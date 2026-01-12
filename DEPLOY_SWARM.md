# Deploy Chatwoot na sua Infraestrutura Swarm

Guia para deployar o Chatwoot usando seu PostgreSQL e Redis existentes na rede `rede_interna`.

## Sua Infraestrutura Atual

✅ **PostgreSQL**: `postgres` (senha: `18d66c7e69de8f1dd34b715552f366d7`)
✅ **Redis**: `n8n_redis` (sem senha, porta 6379)
✅ **Rede**: `rede_interna`

O Chatwoot vai usar:
- Seu PostgreSQL existente (criará database `chatwoot`)
- Seu Redis do n8n (usará database 2 - separado do n8n que usa db 1)

---

## Passo 1: Preparar na VPS

Você já fez isso! ✅

```bash
cd ~/chatwoot-custom
```

---

## Passo 2: Criar Volume para Storage

```bash
docker volume create chatwoot_storage
```

---

## Passo 3: Gerar SECRET_KEY_BASE

```bash
openssl rand -hex 64
```

**Copie o resultado** - você vai precisar!

---

## Passo 4: Criar arquivo .env para Deploy

Crie um arquivo `.env.deploy` na VPS:

```bash
nano ~/chatwoot-custom/.env.deploy
```

Cole este conteúdo (substitua o SECRET_KEY_BASE):

```bash
SECRET_KEY_BASE=COLE_AQUI_O_RESULTADO_DO_OPENSSL
FRONTEND_URL=http://chat.adavance.com.br:3000
```

Salve: `Ctrl+O`, `Enter`, `Ctrl+X`

---

## Passo 5: Puxar a Imagem Oficial do Chatwoot

Em vez de buildar (que é pesado), vamos usar a imagem oficial:

```bash
docker pull chatwoot/chatwoot:latest
```

Isso vai baixar a imagem pronta (mais rápido e leve).

**Nota:** Suas customizações da branch `feature/kanban-crm` serão aplicadas depois via volumes ou você pode buildar a imagem em uma máquina mais potente e fazer push para Docker Hub.

---

## Passo 6: Criar Database no PostgreSQL

Antes de subir o Chatwoot, crie o database. Primeiro, identifique o container correto do Postgres:

```bash
docker ps | grep postgres
```

Você verá vários containers. Use o container **postgres_postgres** (Postgres 14 da stack ORION):

```bash
# Listar containers e pegar o ID/nome do postgres_postgres
docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}" | grep postgres_postgres

# Criar database usando o CONTAINER_ID ou nome completo
docker exec CONTAINER_ID psql -U postgres -c "CREATE DATABASE chatwoot;"

# Exemplo (substitua pelo ID correto):
# docker exec f5b321fa94d0 psql -U postgres -c "CREATE DATABASE chatwoot;"
```

Se já existir, ignore o erro.

---

## Passo 7: Deploy via Portainer

### Opção A: Via Portainer UI (Recomendado)

1. Acesse Portainer: `http://chat.adavance.com.br:9000`
2. Vá em **Stacks** → **Add Stack**
3. Nome: `chatwoot`
4. **Build method**: Web editor
5. Cole o conteúdo do arquivo `docker-compose.swarm.yaml`:

```yaml
version: "3.7"

services:
  chatwoot_rails:
    image: chatwoot-custom:feature-kanban-crm

    networks:
      - rede_interna

    ports:
      - "3000:3000"

    environment:
      - POSTGRES_DATABASE=chatwoot
      - POSTGRES_HOST=postgres
      - POSTGRES_PORT=5432
      - POSTGRES_USERNAME=postgres
      - POSTGRES_PASSWORD=18d66c7e69de8f1dd34b715552f366d7
      - DATABASE_URL=postgresql://postgres:18d66c7e69de8f1dd34b715552f366d7@postgres:5432/chatwoot
      - REDIS_URL=redis://n8n_redis:6379/2
      - REDIS_PASSWORD=
      - RAILS_ENV=production
      - NODE_ENV=production
      - INSTALLATION_ENV=docker
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - FRONTEND_URL=${FRONTEND_URL}
      - RAILS_LOG_TO_STDOUT=true
      - TZ=America/Sao_Paulo
      - ENABLE_ACCOUNT_SIGNUP=false
      - FORCE_SSL=false

    volumes:
      - chatwoot_storage:/app/storage

    entrypoint: docker/entrypoints/rails.sh
    command: ['bundle', 'exec', 'rails', 's', '-p', '3000', '-b', '0.0.0.0']

    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: "2"
          memory: 2048M

  chatwoot_sidekiq:
    image: chatwoot-custom:feature-kanban-crm

    networks:
      - rede_interna

    environment:
      - POSTGRES_DATABASE=chatwoot
      - POSTGRES_HOST=postgres
      - POSTGRES_PORT=5432
      - POSTGRES_USERNAME=postgres
      - POSTGRES_PASSWORD=18d66c7e69de8f1dd34b715552f366d7
      - DATABASE_URL=postgresql://postgres:18d66c7e69de8f1dd34b715552f366d7@postgres:5432/chatwoot
      - REDIS_URL=redis://n8n_redis:6379/2
      - REDIS_PASSWORD=
      - RAILS_ENV=production
      - NODE_ENV=production
      - INSTALLATION_ENV=docker
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - RAILS_LOG_TO_STDOUT=true
      - TZ=America/Sao_Paulo

    volumes:
      - chatwoot_storage:/app/storage

    command: ['bundle', 'exec', 'sidekiq', '-C', 'config/sidekiq.yml']

    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: "1"
          memory: 1024M

volumes:
  chatwoot_storage:
    external: true
    name: chatwoot_storage

networks:
  rede_interna:
    external: true
    name: rede_interna
```

6. Em **Environment variables**, adicione:
   ```
   SECRET_KEY_BASE=seu_secret_key_base_gerado
   FRONTEND_URL=http://n8neditor.adavance.com.br:3000
   ```

7. Clique em **Deploy the stack**

### Opção B: Via Terminal

```bash
cd ~/chatwoot-custom
docker stack deploy -c docker-compose.swarm.yaml chatwoot --with-registry-auth
```

---

## Passo 8: Executar Migrations

Aguarde 2-3 minutos para os containers iniciarem, depois:

```bash
# Encontrar o container do Rails
docker ps | grep chatwoot_rails

# Executar migrations (substitua CONTAINER_ID)
docker exec -it CONTAINER_ID bundle exec rails db:chatwoot_prepare
```

Ou de forma automática:

```bash
docker exec -it $(docker ps -q -f name=chatwoot_rails) bundle exec rails db:chatwoot_prepare
```

---

## Passo 9: Criar Conta Admin

```bash
docker exec -it $(docker ps -q -f name=chatwoot_rails) bundle exec rails console
```

No console Rails, cole:

```ruby
account = Account.create!(name: 'Adavance')
user = User.create!(
  name: 'Admin',
  email: 'admin@adavance.com.br',
  password: 'SuaSenhaSegura123!',
  account: account,
  role: :administrator
)
puts "✅ Usuário criado: #{user.email}"
exit
```

---

## Passo 10: Acessar Chatwoot

Acesse: **http://n8neditor.adavance.com.br:3000**

Login:
- **Email**: `admin@adavance.com.br`
- **Senha**: `SuaSenhaSegura123!`

---

## Ver Logs

```bash
# Rails
docker logs -f $(docker ps -q -f name=chatwoot_rails)

# Sidekiq
docker logs -f $(docker ps -q -f name=chatwoot_sidekiq)

# Via Portainer: Stacks → chatwoot → Logs
```

---

## Atualizar Deploy (após novos commits)

```bash
cd ~/chatwoot-custom
git pull origin feature/kanban-crm
docker build -f docker/Dockerfile -t chatwoot-custom:feature-kanban-crm .
docker service update --force chatwoot_chatwoot_rails
docker service update --force chatwoot_chatwoot_sidekiq
```

---

## Troubleshooting

### Container não inicia

```bash
# Ver logs
docker service logs chatwoot_chatwoot_rails

# Ver status
docker service ps chatwoot_chatwoot_rails
```

### Erro de conexão com Postgres

Verifique se o database existe:

```bash
docker exec -it $(docker ps -q -f name=postgres) psql -U postgres -l | grep chatwoot
```

### Erro de conexão com Redis

Teste conexão:

```bash
docker exec -it $(docker ps -q -f name=n8n_redis) redis-cli ping
```

---

## Configurar SSL (Opcional)

Se quiser usar HTTPS, configure um proxy reverso (Nginx/Traefik) na frente do Chatwoot.

---

## Backup

### Backup do Database

```bash
docker exec $(docker ps -q -f name=postgres) pg_dump -U postgres chatwoot > chatwoot_backup_$(date +%Y%m%d).sql
```

### Backup dos Arquivos

```bash
docker run --rm -v chatwoot_storage:/data -v $(pwd):/backup alpine tar czf /backup/chatwoot_storage_$(date +%Y%m%d).tar.gz -C /data .
```

---

## Desinstalar

```bash
docker stack rm chatwoot
docker volume rm chatwoot_storage
docker exec -it $(docker ps -q -f name=postgres) psql -U postgres -c "DROP DATABASE chatwoot;"
```
