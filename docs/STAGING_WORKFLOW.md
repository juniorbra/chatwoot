# Workflow de Staging com Docker Swarm

## 📋 Visão Geral

Este guia explica como usar o ambiente de **staging** no dia a dia para testar mudanças antes de ir para produção.

### Arquitetura Atual

```
┌─────────────────────────────────────────┐
│          Traefik (Reverse Proxy)         │
│     :80 → :443 (SSL/TLS)                │
└─────────┬───────────────────────┬────────┘
          │                       │
          ▼                       ▼
┌─────────────────┐     ┌──────────────────┐
│   PRODUÇÃO      │     │    STAGING       │
│ botvance.com.br │     │ staging.botvance │
├─────────────────┤     ├──────────────────┤
│ Stack: chatwoot │     │ Stack: staging   │
│ - Rails (3000)  │     │ - Rails (3001)   │
│ - Sidekiq       │     │ - Sidekiq        │
│ - PostgreSQL    │     │ (usa PG comum)   │
│ - Redis         │     │ (usa Redis comum)│
└─────────────────┘     └──────────────────┘
```

**Diretórios**:
- Produção: `/chatwoot-custom` (ou equivalente)
- Staging: `~/chatwoot-staging`

**Bancos de Dados**:
- Produção: `chatwoot` (padrão)
- Staging: `chatwoot_staging`

---

## 🔄 Workflow Completo

### Cenário 1: Testar Sync Upstream

Você criou um branch de teste (ex: `test/sync-20260205`) e quer testar antes de aplicar em produção.

#### Passo 1: Atualizar Staging

```bash
# 1. Entrar no diretório do staging
cd ~/chatwoot-staging

# 2. Fazer backup do branch atual (opcional, mas recomendado)
git branch backup-$(date +%Y%m%d-%H%M%S)

# 3. Buscar novas branches/tags
git fetch origin

# 4. Checkout no branch de teste
git checkout test/sync-20260205
# Ou se for tag:
# git checkout v4.11.0-botvance.1

# 5. Verificar se há migrations pendentes
git diff HEAD@{1} db/migrate/
```

#### Passo 2: Atualizar Stack Docker

```bash
# 1. Rebuild da imagem (se necessário)
# Se você fez mudanças de código, precisa rebuildar
docker build -t ghcr.io/juniorbra/chatwoot:staging-test .

# 2. Atualizar .env.staging se necessário
nano .env.staging

# 3. Fazer deploy da stack atualizada
docker stack deploy -c docker-compose.swarm.yaml chatwoot-staging

# 4. Aguardar serviços subirem
docker service ls | grep staging

# Deve mostrar 1/1 em REPLICAS:
# chatwoot-staging_chatwoot_rails_staging     1/1
# chatwoot-staging_chatwoot_sidekiq_staging   1/1
```

#### Passo 3: Rodar Migrations

```bash
# Executar migrations no container staging
docker exec -it $(docker ps -q -f name=chatwoot-staging.*rails) \
  bundle exec rails db:migrate RAILS_ENV=staging

# Verificar status das migrations
docker exec -it $(docker ps -q -f name=chatwoot-staging.*rails) \
  bundle exec rails db:migrate:status RAILS_ENV=staging
```

#### Passo 4: Testar no Staging

Acesse **https://staging.botvance.com.br** e siga a checklist:

##### ✅ Checklist de Testes Básicos

- [ ] **Login/Logout** funciona
- [ ] **Dashboard** carrega sem erros
- [ ] **Criar nova conversa** funciona
- [ ] **Enviar mensagem** funciona
- [ ] **Receber mensagem** funciona
- [ ] **Attachments** (imagens, arquivos) funcionam
- [ ] **Notificações** aparecem
- [ ] **WebSocket** conecta (console sem erros)

##### ✅ Checklist de Funcionalidades Customizadas

- [ ] **Pipeline/Kanban** aparece no menu lateral
- [ ] **Drag & drop** de conversas entre stages funciona
- [ ] **Mudança de stage** persiste após reload
- [ ] **Logos customizados** aparecem
- [ ] **Favicons** corretos
- [ ] **i18n PT-BR** funcionando

##### ✅ Checklist de Performance

- [ ] **Página carrega em <3 segundos**
- [ ] **Console do browser** (F12) sem erros críticos
- [ ] **Logs do servidor** sem exceptions

**Ver logs em tempo real**:

```bash
# Logs do Rails
docker logs -f $(docker ps -q -f name=chatwoot-staging.*rails) 2>&1 | grep -i error

# Logs do Sidekiq
docker logs -f $(docker ps -q -f name=chatwoot-staging.*sidekiq) 2>&1 | grep -i error
```

#### Passo 5: Teste por 3-7 dias

- Deixe o staging rodando com o novo código
- Use diariamente para suas operações (se possível)
- Convide cliente piloto para testar
- Monitore logs diariamente:

```bash
# Ver últimos erros (últimas 100 linhas)
docker logs --tail 100 $(docker ps -q -f name=chatwoot-staging.*rails) 2>&1 | grep -i error
```

#### Passo 6: Se tudo OK → Promover para Produção

Se tudo funcionou bem no staging por 3-7 dias:

```bash
# 1. Fazer merge no branch principal (feature/kanban-crm)
cd ~/chatwoot-staging
git checkout feature/kanban-crm
git merge test/sync-20260205

# 2. Criar tag de produção
git tag v4.11.0-botvance.1
git push origin v4.11.0-botvance.1

# 3. Deploy em produção (no diretório de produção)
cd /opt/chatwoot  # ou onde estiver sua produção
git fetch origin
git checkout v4.11.0-botvance.1

# 4. Rodar migrations em produção
docker exec -it $(docker ps -q -f name=chatwoot_chatwoot_rails) \
  bundle exec rails db:migrate RAILS_ENV=production

# 5. Atualizar stack de produção
docker stack deploy -c docker-compose.swarm.yaml chatwoot

# 6. Verificar se subiu corretamente
docker service ls | grep chatwoot
docker logs --tail 50 $(docker ps -q -f name=chatwoot_chatwoot_rails)
```

---

### Cenário 2: Testar Nova Funcionalidade (sem sync)

Você desenvolveu uma nova feature no branch `feature/kanban-crm` e quer testar.

```bash
# 1. Ir para staging
cd ~/chatwoot-staging

# 2. Checkout no branch de feature
git fetch origin
git checkout feature/kanban-crm
git pull origin feature/kanban-crm

# 3. Rebuild da imagem (se mudou código)
docker build -t ghcr.io/juniorbra/chatwoot:staging-feature .

# 4. Atualizar stack
docker stack deploy -c docker-compose.swarm.yaml chatwoot-staging

# 5. Rodar migrations (se houver)
docker exec -it $(docker ps -q -f name=chatwoot-staging.*rails) \
  bundle exec rails db:migrate RAILS_ENV=staging

# 6. Testar seguindo checklist acima
```

---

### Cenário 3: Rollback (se algo deu errado)

Se o staging quebrou após um deploy:

```bash
# 1. Voltar para branch/tag anterior
cd ~/chatwoot-staging
git checkout v4.10.1-botvance.1  # versão anterior estável

# 2. Rollback das migrations (se necessário)
docker exec -it $(docker ps -q -f name=chatwoot-staging.*rails) \
  bundle exec rails db:rollback RAILS_ENV=staging STEP=2  # ajustar STEP

# 3. Rebuild e redeploy
docker build -t ghcr.io/juniorbra/chatwoot:staging-rollback .
docker stack deploy -c docker-compose.swarm.yaml chatwoot-staging

# 4. Verificar se voltou ao normal
docker logs --tail 50 $(docker ps -q -f name=chatwoot-staging.*rails)
```

---

## 🛠️ Comandos Úteis

### Ver status dos serviços

```bash
# Ver todas as stacks
docker stack ls

# Ver serviços do staging
docker service ls | grep staging

# Ver logs em tempo real
docker logs -f $(docker ps -q -f name=chatwoot-staging.*rails)

# Ver últimas 100 linhas de log
docker logs --tail 100 $(docker ps -q -f name=chatwoot-staging.*rails)
```

### Acessar Rails Console no Staging

```bash
# Abrir console Rails no staging
docker exec -it $(docker ps -q -f name=chatwoot-staging.*rails) \
  bundle exec rails console RAILS_ENV=staging

# Exemplo de comandos úteis no console:
# > User.count
# > Account.first
# > Conversation.last
```

### Resetar Banco de Dados Staging

⚠️ **CUIDADO**: Isso apaga todos os dados do staging!

```bash
# 1. Conectar ao PostgreSQL
docker exec -it $(docker ps -q -f name=chatwoot.*postgres) psql -U postgres

# 2. Dropar e recriar banco
DROP DATABASE chatwoot_staging;
CREATE DATABASE chatwoot_staging;
GRANT ALL PRIVILEGES ON DATABASE chatwoot_staging TO postgres;
\q

# 3. Rodar migrations e seed
docker exec -it $(docker ps -q -f name=chatwoot-staging.*rails) bash -c "
  bundle exec rails db:migrate RAILS_ENV=staging && \
  bundle exec rails db:seed RAILS_ENV=staging
"
```

### Verificar diferenças entre Staging e Produção

```bash
cd ~/chatwoot-staging

# Ver diferenças de código
git diff v4.10.1-botvance.1 v4.11.0-botvance.1

# Ver diferenças de migrations
git diff v4.10.1-botvance.1 v4.11.0-botvance.1 db/migrate/

# Ver diferenças de schema
git diff v4.10.1-botvance.1 v4.11.0-botvance.1 db/schema.rb
```

### Monitorar Performance

```bash
# Ver uso de CPU/memória dos containers
docker stats $(docker ps -q -f name=chatwoot-staging)

# Ver processos rodando no container
docker exec -it $(docker ps -q -f name=chatwoot-staging.*rails) ps aux

# Ver conexões ativas no banco (staging)
docker exec -it $(docker ps -q -f name=chatwoot.*postgres) \
  psql -U postgres -c "SELECT datname, count(*) FROM pg_stat_activity WHERE datname='chatwoot_staging' GROUP BY datname;"
```

---

## 📊 Fluxo Recomendado (Resumo Visual)

```
┌────────────────────────────────────────────────────┐
│ 1. Criar branch de teste (test/sync-YYYYMMDD)     │
│    no repositório local                           │
└─────────────────┬──────────────────────────────────┘
                  ▼
┌────────────────────────────────────────────────────┐
│ 2. Fazer checkout no STAGING                      │
│    git checkout test/sync-YYYYMMDD                │
└─────────────────┬──────────────────────────────────┘
                  ▼
┌────────────────────────────────────────────────────┐
│ 3. Rebuild imagem + Deploy stack                  │
│    docker build + docker stack deploy             │
└─────────────────┬──────────────────────────────────┘
                  ▼
┌────────────────────────────────────────────────────┐
│ 4. Rodar migrations                               │
│    docker exec ... rails db:migrate               │
└─────────────────┬──────────────────────────────────┘
                  ▼
┌────────────────────────────────────────────────────┐
│ 5. Testar por 3-7 dias                            │
│    Seguir checklist de testes                     │
└─────────────────┬──────────────────────────────────┘
                  ▼
         ┌────────┴────────┐
         ▼                 ▼
    ┌─────────┐      ┌──────────┐
    │ TUDO OK │      │ DEU ERRO │
    └────┬────┘      └─────┬────┘
         │                 │
         ▼                 ▼
  ┌──────────────┐  ┌─────────────┐
  │ 6a. Merge    │  │ 6b. Rollback│
  │ para prod    │  │ Investigar  │
  └──────────────┘  └─────────────┘
```

---

## 🚨 Troubleshooting

### Problema: Staging não está respondendo

```bash
# 1. Verificar se os serviços estão rodando
docker service ls | grep staging

# Se REPLICAS mostrar 0/1:
# 2. Ver logs do serviço
docker service logs chatwoot-staging_chatwoot_rails_staging

# 3. Remover e recriar stack
docker stack rm chatwoot-staging
sleep 10
docker stack deploy -c docker-compose.swarm.yaml chatwoot-staging
```

### Problema: Erro 500 no staging

```bash
# 1. Ver logs detalhados
docker logs --tail 200 $(docker ps -q -f name=chatwoot-staging.*rails) | grep -i -A 5 error

# 2. Ver se migrations estão pendentes
docker exec -it $(docker ps -q -f name=chatwoot-staging.*rails) \
  bundle exec rails db:migrate:status RAILS_ENV=staging

# 3. Verificar variáveis de ambiente
docker exec -it $(docker ps -q -f name=chatwoot-staging.*rails) printenv | grep RAILS_ENV
```

### Problema: Banco de dados não conecta

```bash
# 1. Verificar se PostgreSQL está rodando
docker ps | grep postgres

# 2. Testar conexão manual
docker exec -it $(docker ps -q -f name=chatwoot.*postgres) \
  psql -U postgres -d chatwoot_staging -c "SELECT 1;"

# 3. Verificar .env.staging
cd ~/chatwoot-staging
grep POSTGRES .env.staging
```

---

## 🎯 Boas Práticas

1. **Sempre teste no staging primeiro** - Nunca vá direto para produção
2. **Mantenha staging atualizado** - Sincronize com produção semanalmente
3. **Use cliente piloto** - Peça para um cliente menos crítico validar
4. **Monitore logs** - Verifique logs diariamente durante testes
5. **Documente problemas** - Anote bugs encontrados e como resolveu
6. **Backup antes de grandes mudanças** - Faça snapshot do banco se for mudança arriscada
7. **Não use dados de produção** - LGPD/GDPR! Use dados fictícios

---

## ⚠️ Avisos Importantes

### 🔒 Segurança

- **SECRET_KEY_BASE** do staging DEVE ser diferente da produção
- **Não compartilhe** credenciais do staging publicamente
- **Não exponha** staging em redes públicas sem autenticação

### 🗄️ Dados

- **Staging não é backup** - Pode ser destruído a qualquer momento
- **Não use dados reais de clientes** - LGPD/GDPR!
- **Dados podem ser perdidos** - Não armazene nada crítico

### 🔄 Sincronização

- **Não sincronize banco staging → produção** - Só código!
- **Migrations são irreversíveis** - Teste com cuidado
- **Schema.rb pode causar conflitos** - Veja docs/GIT_WORKFLOW.md

---

## 📝 Checklist de Deploy

Use esta checklist toda vez que for promover staging → produção:

- [ ] Testado no staging por **pelo menos 3 dias**
- [ ] Cliente piloto validou (se aplicável)
- [ ] Logs sem erros críticos
- [ ] Performance aceitável (<3s carregamento)
- [ ] Migrations testadas no staging
- [ ] Backup de produção feito
- [ ] Janela de manutenção comunicada (se necessário)
- [ ] Plano de rollback definido
- [ ] Tag de versão criada (ex: v4.11.0-botvance.1)
- [ ] Merge feito no branch principal
- [ ] Deploy em produção executado
- [ ] Verificação pós-deploy OK

---

*Documentação criada em: 2026-02-05*
*Última atualização: v4.10.1-botvance.1*
*Ambiente: Docker Swarm + Traefik*
