# Guia de Staging Environment

⚠️ **IMPORTANTE**: Você atualmente não tem ambiente de staging configurado. Este guia explica **por que precisa** e **como configurar**.

---

## 🎯 O que é Staging?

**Staging** é um ambiente de teste **idêntico à produção**, mas **separado**.

### Analogia simples:

Imagine que você tem uma loja física:

- **Produção** = Loja aberta, clientes comprando
- **Staging** = Loja fechada para testes, você testa produtos novos
- **Desenvolvimento** = Seu escritório/oficina

```
Desenvolvimento → Staging (teste) → Produção (clientes reais)
     ↓                ↓                    ↓
   Seu PC      Servidor de teste    Servidor dos clientes
```

---

## ❗ Por que você PRECISA de Staging?

### Sem Staging:

❌ Sync upstream vai **direto** para produção
❌ Se quebrar algo, **clientes são afetados**
❌ Rollback é **estressante e demorado**
❌ Descobrir bugs **depois** que clientes reclamaram

### Com Staging:

✅ Testa sync **antes** de afetar clientes
✅ Descobre bugs em **ambiente seguro**
✅ Rollback é **fácil** (só não fazer deploy)
✅ Cliente piloto valida **sem risco**

---

## 🏗️ Opções de Staging (do mais simples ao mais completo)

### Opção 1: Segunda Instância no Mesmo Servidor (RECOMENDADO para começar)

**Custo**: Grátis (usa servidor atual)
**Tempo setup**: 15-30 minutos
**Complexidade**: Baixa

**Como funciona**:
- Mesma VPS que produção
- Porta diferente (ex: produção 3000, staging 3001)
- Banco de dados separado
- Subdomínio separado (staging.seusite.com)

#### Setup Passo a Passo:

```bash
# 1. Clonar diretório de produção
cd /opt
sudo cp -r chatwoot chatwoot-staging

# 2. ⚠️ CRÍTICO: Corrigir permissões (evita erros de escrita)
sudo chown -R chatwoot:chatwoot /opt/chatwoot-staging

# 3. Entrar no staging
cd chatwoot-staging

# 4. Criar arquivo .env separado
cp .env .env.staging

# 5. Gerar SECRET_KEY_BASE nova (segurança!)
cd /opt/chatwoot-staging
bundle exec rails secret > /tmp/staging_secret.txt
echo "Nova SECRET_KEY_BASE gerada em: /tmp/staging_secret.txt"
cat /tmp/staging_secret.txt

# 6. Editar .env.staging
nano .env.staging
```

**Por que o `chown` é crítico?**
- `sudo cp -r` copia com owner original (pode ser root)
- Chatwoot precisa escrever logs, compilar assets, uploads
- Sem permissão correta = erros 500 misteriosos

**Configurações importantes no .env.staging**:

```env
# Mudar porta
RAILS_ENV=staging
PORT=3001  # Diferente da produção (3000)

# Banco de dados separado
DATABASE_URL=postgresql://user:pass@localhost:5432/chatwoot_staging

# Redis separado (ou usar db diferente)
REDIS_URL=redis://localhost:6379/2  # Produção usa /1

# 🔐 Secret key DIFERENTE (copiar do /tmp/staging_secret.txt)
SECRET_KEY_BASE=cole_aqui_a_chave_gerada_pelo_rails_secret

# URL do staging
FRONTEND_URL=https://staging.seusite.com
```

**⚠️ Por que SECRET_KEY_BASE diferente?**
- Evita conflito de cookies/sessões entre staging e produção
- Se alguém acessar staging.seusite.com e depois seusite.com (produção), não vai ter problema de sessão
- Segurança: se vazar secret do staging, produção não é comprometida

**Criar banco staging**:

```bash
# 1. Conectar ao PostgreSQL
sudo -u postgres psql

# 2. Criar banco
CREATE DATABASE chatwoot_staging;
GRANT ALL PRIVILEGES ON DATABASE chatwoot_staging TO chatwoot_user;
\q

# 3. Rodar migrations
cd /opt/chatwoot-staging
RAILS_ENV=staging bundle exec rails db:migrate
RAILS_ENV=staging bundle exec rails db:seed
```

**Configurar Nginx** (subdomínio staging):

```nginx
# /etc/nginx/sites-available/staging-chatwoot
upstream staging_chatwoot {
  server 127.0.0.1:3001;
}

server {
  listen 80;
  server_name staging.seusite.com;

  # Redirecionar para HTTPS
  return 301 https://$host$request_uri;
}

server {
  listen 443 ssl http2;
  server_name staging.seusite.com;

  ssl_certificate /etc/letsencrypt/live/staging.seusite.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/staging.seusite.com/privkey.pem;

  root /opt/chatwoot-staging/public;

  location / {
    proxy_pass http://staging_chatwoot;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

**Ativar configuração**:

```bash
sudo ln -s /etc/nginx/sites-available/staging-chatwoot /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Configurar SSL
sudo certbot --nginx -d staging.seusite.com
```

**Criar script de deploy staging**:

```bash
# /opt/chatwoot-staging/deploy-staging.sh
#!/bin/bash
set -e

echo "🚀 Deploying to STAGING..."

# 1. Pull código
git fetch origin
git checkout $1  # Tag ou branch

# 2. Instalar dependências
bundle install
yarn install

# 3. Assets
RAILS_ENV=staging bundle exec rails assets:precompile

# 4. Migrations
RAILS_ENV=staging bundle exec rails db:migrate

# 5. Restart
sudo systemctl restart chatwoot-staging

echo "✅ Staging deployed!"
```

**Criar serviço systemd**:

```ini
# /etc/systemd/system/chatwoot-staging.service
[Unit]
Description=Chatwoot Staging
After=network.target

[Service]
Type=simple
User=chatwoot
WorkingDirectory=/opt/chatwoot-staging
Environment="RAILS_ENV=staging"
Environment="PORT=3001"
ExecStart=/home/chatwoot/.rbenv/shims/bundle exec rails server -p 3001
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

**Ativar serviço**:

```bash
sudo systemctl daemon-reload
sudo systemctl enable chatwoot-staging
sudo systemctl start chatwoot-staging
sudo systemctl status chatwoot-staging
```

---

### Opção 2: Docker Local (Para testes rápidos)

**Custo**: Grátis
**Tempo setup**: 10 minutos
**Complexidade**: Baixa

**Quando usar**: Testes rápidos no seu PC antes de fazer deploy

#### Setup:

```bash
# 1. Clonar repositório
cd ~/projects
git clone https://github.com/juniorbra/chatwoot.git chatwoot-staging
cd chatwoot-staging

# 2. Checkout branch de teste
git checkout test/sync-20260205

# 3. Subir com Docker Compose
cp .env.example .env
# Editar .env conforme necessário
docker-compose up -d

# 4. Rodar migrations
docker-compose exec web bundle exec rails db:migrate

# 5. Acessar
open http://localhost:3000
```

**Parar tudo**:

```bash
docker-compose down
```

**Vantagens**:
- ✅ Rápido para testar localmente
- ✅ Isolado do seu ambiente de produção
- ✅ Fácil de destruir e recriar

**Desvantagens**:
- ❌ Não é acessível por outras pessoas
- ❌ Dados não persistem entre reinicializações
- ❌ Não testa em ambiente similar a produção

---

### Opção 3: VPS Separada (Ideal, mas custa)

**Custo**: $5-10/mês (VPS pequena)
**Tempo setup**: 1-2 horas
**Complexidade**: Média

**Quando usar**: Se tiver orçamento e quiser staging profissional

#### Provedores recomendados:

- **DigitalOcean**: $6/mês (droplet 1GB RAM)
- **Vultr**: $5/mês (1GB RAM)
- **Hetzner**: €4/mês (mais barato, Europa)

#### Setup:

Igual ao setup de produção, mas:
- Servidor dedicado
- Subdomínio staging.seusite.com
- Banco de dados separado
- Redis separado

**Referência**: Seguir documentação oficial Chatwoot

---

## 🔄 Workflow com Staging

### Antes de sync upstream:

```bash
# 1. Deploy branch de teste no staging
cd /opt/chatwoot-staging
git fetch origin
git checkout test/sync-20260205
RAILS_ENV=staging bundle exec rails db:migrate
sudo systemctl restart chatwoot-staging

# 2. Testar por 3-7 dias
# - Acessar staging.seusite.com
# - Testar funcionalidades críticas
# - Cliente piloto valida

# 3. Se tudo OK, fazer merge no feature/kanban-crm
# (ver docs/GIT_WORKFLOW.md)

# 4. Deploy em produção
cd /opt/chatwoot
git checkout v4.11.0-botvance.1
RAILS_ENV=production bundle exec rails db:migrate
sudo systemctl restart chatwoot
```

---

## 🎯 Recomendação IMEDIATA

**Para sua situação (sem staging agora)**:

1. **Curto prazo (AGORA)**: Use **Opção 1 - Segunda instância no mesmo servidor**
   - Setup rápido (30 min)
   - Grátis
   - Suficiente para testes

2. **Médio prazo (próximos meses)**: Migrar para **Opção 3 - VPS separada**
   - Quando tiver mais clientes
   - Quando budget permitir
   - Mais profissional

**NÃO faça sync sem staging!** O risco é muito alto.

---

## 📋 Checklist de Setup (Opção 1)

Use este checklist quando for configurar:

- [ ] Clonar diretório de produção
- [ ] Criar .env.staging com configurações diferentes
- [ ] Criar banco de dados staging
- [ ] Rodar migrations
- [ ] Configurar subdomínio (staging.seusite.com)
- [ ] Configurar Nginx
- [ ] Gerar certificado SSL (certbot)
- [ ] Criar serviço systemd
- [ ] Criar script de deploy
- [ ] Testar acesso via browser
- [ ] Fazer login e testar funcionalidades
- [ ] Documentar credenciais de acesso

---

## 🧪 Como Testar (Checklist)

Toda vez que fizer deploy em staging:

### Funcionalidades Básicas:
- [ ] Login/Logout
- [ ] Dashboard carrega
- [ ] Criar nova conversa
- [ ] Enviar mensagem
- [ ] Receber mensagem

### Funcionalidades Customizadas:
- [ ] Pipeline/Kanban aparece no menu
- [ ] Drag & drop de conversas funciona
- [ ] Mudança de stage persiste no banco
- [ ] Logos customizados aparecem
- [ ] Favicons corretos
- [ ] i18n PT-BR funcionando

### Performance:
- [ ] Página carrega em <3 segundos
- [ ] Sem erros no console do browser (F12)
- [ ] Sem erros no log do servidor

```bash
# Ver logs em tempo real
tail -f /opt/chatwoot-staging/log/staging.log

# Ver logs do sistema
sudo journalctl -u chatwoot-staging -f
```

---

## 📞 Próximos Passos

1. **Decidir qual opção usar** (recomendo Opção 1)
2. **Bloquear 1-2 horas para setup**
3. **Seguir checklist acima**
4. **Testar staging** com um sync de teste
5. **Documentar acesso** (URL, credenciais, como fazer deploy)

---

## ❓ FAQ

### P: Staging precisa ter dados reais?

R: **Não necessariamente**. Pode ter:
- Dados de seed (padrão do Rails)
- Cópia de produção (mais realista, mas cuidado com LGPD/GDPR)
- Dados fictícios gerados

### P: Preciso fazer backup do staging?

R: **Não é crítico**. Staging é descartável. Se quebrar, recria.

### P: Cliente piloto vai usar staging?

R: **Sim, idealmente**. Cliente menos crítico testa primeiro. Se tudo OK, vai pra produção.

### P: Staging precisa estar sempre no ar?

R: **Não**. Pode subir só quando for testar sync. Mas é útil estar sempre disponível.

---

*Documentação gerada em: 2026-02-05*
*Última atualização: v4.10.1-botvance.1*
