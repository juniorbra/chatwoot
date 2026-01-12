# Deploy Chatwoot Custom no Portainer

Guia completo para deployar sua versão customizada do Chatwoot (branch `feature/kanban-crm`) usando Portainer na VPS.

## Pré-requisitos

- VPS com Docker instalado
- Portainer instalado e rodando
- Acesso SSH à VPS
- Token GitHub para clonar repositório privado (se for o caso)

## Opção 1: Deploy via Git Repository (Recomendado)

### Passo 1: Preparar a VPS

Conecte via SSH na sua VPS e execute:

```bash
# Criar diretório para o projeto
mkdir -p ~/chatwoot-custom
cd ~/chatwoot-custom

# Clonar o repositório (branch customizada)
git clone -b feature/kanban-crm https://github.com/juniorbra/chatwoot.git .

# Se o repo for privado, use com token:
# git clone -b feature/kanban-crm https://juniorbra:SEU_TOKEN@github.com/juniorbra/chatwoot.git .
```

### Passo 2: Configurar Variáveis de Ambiente

```bash
# Copiar arquivo de exemplo
cp .env.example .env

# Editar com suas configurações
nano .env
```

**Variáveis mínimas necessárias (edite no .env):**

```bash
# Database
POSTGRES_PASSWORD=SuaSenhaSegura123
POSTGRES_DB=chatwoot
POSTGRES_USER=postgres

# Redis
REDIS_PASSWORD=SuaSenhaRedis123

# Rails
SECRET_KEY_BASE=$(openssl rand -hex 64)
FRONTEND_URL=http://seu-dominio.com
RAILS_ENV=production

# Database URLs
DATABASE_URL=postgresql://postgres:SuaSenhaSegura123@postgres:5432/chatwoot
REDIS_URL=redis://default:SuaSenhaRedis123@redis:6379
```

**Gerar SECRET_KEY_BASE:**
```bash
openssl rand -hex 64
```

### Passo 3: Deploy no Portainer

1. Acesse seu Portainer (ex: `http://sua-vps:9000`)
2. Vá em **Stacks** → **Add Stack**
3. Dê um nome: `chatwoot-custom`
4. Em **Build method**, escolha: **Repository**
5. Configure:
   - **Repository URL**: `https://github.com/juniorbra/chatwoot`
   - **Repository reference**: `refs/heads/feature/kanban-crm`
   - **Compose path**: `docker-compose.portainer.yaml`

   Se o repositório for privado:
   - Marque **Authentication**
   - **Username**: `juniorbra`
   - **Personal Access Token**: seu token GitHub

6. Em **Environment variables**, adicione as variáveis do arquivo .env:
   ```
   POSTGRES_PASSWORD=SuaSenhaSegura123
   REDIS_PASSWORD=SuaSenhaRedis123
   SECRET_KEY_BASE=seu_secret_key_base_gerado
   FRONTEND_URL=http://seu-dominio.com
   DATABASE_URL=postgresql://postgres:SuaSenhaSegura123@postgres:5432/chatwoot
   REDIS_URL=redis://default:SuaSenhaRedis123@redis:6379
   ```

7. Clique em **Deploy the stack**

### Passo 4: Aguardar Build

O Portainer vai:
- Clonar o repositório
- Buildar a imagem Docker (pode demorar 10-20 minutos)
- Subir os containers

**Acompanhe os logs:**
- No Portainer, vá em **Stacks** → **chatwoot-custom** → **Logs**

### Passo 5: Executar Migrations

Após o build, execute as migrations:

```bash
# Via Portainer Console (chatwoot-rails container):
bundle exec rails db:chatwoot_prepare

# Ou via SSH na VPS:
docker exec -it chatwoot-rails bundle exec rails db:chatwoot_prepare
```

### Passo 6: Criar Conta Admin

```bash
# Via Portainer Console ou SSH:
docker exec -it chatwoot-rails bundle exec rails c
```

No console Rails:
```ruby
account = Account.create!(name: 'Acme Inc')
user = User.create!(
  name: 'Admin',
  email: 'admin@seudominio.com',
  password: 'SuperSenha123!',
  account: account,
  role: :administrator
)
```

Digite `exit` para sair do console.

### Passo 7: Acessar Chatwoot

Acesse: `http://sua-vps:3000`

---

## Opção 2: Upload Manual (Stack Composer)

Se preferir não usar git no Portainer:

1. No Portainer, vá em **Stacks** → **Add Stack**
2. Dê um nome: `chatwoot-custom`
3. Em **Build method**, escolha: **Web editor**
4. Cole o conteúdo do arquivo `docker-compose.portainer.yaml`
5. **IMPORTANTE**: Mude a linha de build para usar imagem:
   ```yaml
   # Antes:
   build:
     context: .
     dockerfile: docker/Dockerfile

   # Depois:
   image: chatwoot/chatwoot:latest
   ```
6. Adicione as variáveis de ambiente
7. Deploy

**Nota:** Esta opção usa a imagem oficial, não sua versão customizada. Para usar sua versão, você precisa buildar a imagem localmente primeiro.

---

## Build Local da Imagem (Opcional)

Se quiser buildar localmente e fazer push para Docker Hub:

```bash
# Na sua máquina local
cd /home/hvidi/projects/chatwoot

# Build da imagem
docker build -f docker/Dockerfile -t juniorbra/chatwoot-custom:kanban-crm .

# Login Docker Hub
docker login

# Push da imagem
docker push juniorbra/chatwoot-custom:kanban-crm
```

Depois no Portainer, use:
```yaml
image: juniorbra/chatwoot-custom:kanban-crm
```

---

## Atualizar o Deploy

Para atualizar após novos commits:

**Via Portainer:**
1. Vá em **Stacks** → **chatwoot-custom**
2. Clique em **Pull and redeploy**
3. Confirme

**Via SSH:**
```bash
cd ~/chatwoot-custom
git pull origin feature/kanban-crm
docker-compose -f docker-compose.portainer.yaml up -d --build
```

---

## Portas Expostas

- **3000**: Chatwoot Web UI
- **5432**: PostgreSQL (apenas localhost)
- **6379**: Redis (apenas localhost)

## Volumes Persistentes

- `storage_data`: Arquivos enviados (anexos, avatares)
- `postgres_data`: Banco de dados
- `redis_data`: Cache Redis

---

## Troubleshooting

### Ver logs do Rails:
```bash
docker logs -f chatwoot-rails
```

### Ver logs do Sidekiq:
```bash
docker logs -f chatwoot-sidekiq
```

### Resetar banco de dados:
```bash
docker exec -it chatwoot-rails bundle exec rails db:reset
```

### Parar tudo:
```bash
docker-compose -f docker-compose.portainer.yaml down
```

### Parar e remover volumes:
```bash
docker-compose -f docker-compose.portainer.yaml down -v
```

---

## Próximos Passos

1. Configure um domínio e SSL (Nginx + Let's Encrypt)
2. Configure SMTP para envio de emails
3. Configure storage externo (S3/MinIO) para anexos
4. Configure backup automático do PostgreSQL

---

## Suporte

- Documentação oficial: https://www.chatwoot.com/docs
- Repositório: https://github.com/juniorbra/chatwoot
