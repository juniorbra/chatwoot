# Checklist Executável: Sync Upstream → Produção

**Data de criação**: 2026-02-05
**Status atual**: ✅ v4.10.1-botvance.1 (atualizado)

---

## ⚡ Quick Start (quando houver nova versão)

Execute os comandos na ordem, marcando cada etapa como concluída.

---

## 📍 ETAPA 1: Verificar Nova Versão

```bash
# 1.1 Buscar últimas mudanças
git fetch upstream master
git fetch origin master

# 1.2 Ver quantos commits atrás
git rev-list --left-right --count origin/master...upstream/master
# Output: "X Y" onde X=commits à frente, Y=commits atrás
# Se Y > 0 = TEM UPDATES!

# 1.3 Ver última release oficial
git ls-remote --tags upstream | grep -E 'refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$' | \
  sed 's/.*refs\/tags\///' | sort -V | tail -1

# 1.4 Comparar com sua versão
git describe --tags feature/kanban-crm --abbrev=0
```

**Anotar aqui**:
- [ ] Nova versão upstream: `v______`
- [ ] Minha versão atual: `v______`
- [ ] Commits atrás: `______`

---

## 📖 ETAPA 2: Ler Changelog Oficial

🔗 **URL**: https://github.com/chatwoot/chatwoot/releases

**Procurar por**:
- [ ] ❌ **Breaking changes** (mudanças que quebram código)
- [ ] ⚠️ **Arquivos customizados afetados** (conversation.rb, routes.rb)
- [ ] 🔒 **Security fixes** (prioridade máxima)
- [ ] ✨ **Features novas** que podem conflitar com Pipeline/Kanban

**Anotar breaking changes aqui**:
```
[Exemplo: "Renamed Conversation#status to #state"]



```

---

## 🔄 ETAPA 3: Atualizar origin/master

⚠️ **IMPORTANTE**: master é espelho do upstream, NUNCA commitar nele!

```bash
# 3.1 Ir para master
git checkout master

# 3.2 Mergear upstream (fast-forward only)
git merge upstream/master --ff-only

# Se der erro "não é possível fazer fast-forward":
# = Alguém commitou em master! Investigar:
git log origin/master..upstream/master --oneline
# Resolver manualmente antes de continuar

# 3.3 Fazer push do master atualizado
git push origin master
```

**Status**:
- [ ] ✅ origin/master atualizado sem conflitos

---

## 🧪 ETAPA 4: Criar Branch de Teste

```bash
# 4.1 Voltar para feature/kanban-crm
git checkout feature/kanban-crm

# 4.2 Garantir que está atualizado
git pull origin feature/kanban-crm

# 4.3 Criar branch de teste com data de hoje
# Formato: test/sync-YYYYMMDD
git checkout -b test/sync-$(date +%Y%m%d)

# 4.4 Verificar que está no branch correto
git branch --show-current
# Deve mostrar: test/sync-20260205 (ou data atual)
```

**Status**:
- [ ] ✅ Branch de teste criado: `test/sync-______`

---

## 🔀 ETAPA 5: Fazer Merge (Aqui podem aparecer conflitos)

```bash
# 5.1 Mergear master no branch de teste
git merge master

# ⚠️ Se aparecer conflitos, prossiga para ETAPA 6
# ✅ Se não houver conflitos, pule para ETAPA 7
```

**Conflitos encontrados**:
- [ ] `db/schema.rb` (esperado, sempre conflita)
- [ ] `config/routes.rb` (customizações de rotas)
- [ ] `app/models/conversation.rb` (pipeline_stage)
- [ ] Outros: `_______________`

---

## 🛠️ ETAPA 6: Resolver Conflitos

### 6.1 Resolver schema.rb (SEMPRE conflita)

**Opção A - Script Automático** (recomendado):
```bash
./bin/resolve-schema-conflicts.sh
```

**Opção B - Manual**:
```bash
# Aceitar versão upstream
git checkout --theirs db/schema.rb

# Rodar todas migrations (incluindo customizadas)
bundle exec rails db:migrate

# Regenerar schema limpo
bundle exec rails db:schema:dump

# Adicionar ao commit
git add db/schema.rb
```

### 6.2 Resolver routes.rb (se conflitou)

```bash
# Ver o conflito
git diff config/routes.rb

# Editar manualmente
nano config/routes.rb

# Garantir que suas rotas customizadas estão lá:
# - resources :pipeline_stages

# Adicionar
git add config/routes.rb
```

### 6.3 Resolver conversation.rb (se conflitou)

```bash
# Verificar se pipeline_stage está lá
grep -n "pipeline_stage" app/models/conversation.rb

# Se sumiu, adicionar:
# belongs_to :pipeline_stage, optional: true

# Adicionar
git add app/models/conversation.rb
```

### 6.4 Finalizar merge

```bash
# Depois de resolver todos conflitos
git status  # Ver se há arquivos pendentes

# Continuar merge
git merge --continue

# Ou se quiser abortar:
# git merge --abort
```

**Status**:
- [ ] ✅ Todos conflitos resolvidos
- [ ] ✅ Merge concluído

---

## 🧑‍💻 ETAPA 7: Testar Localmente

```bash
# 7.1 Instalar dependências (caso tenham mudado)
bundle install
pnpm install

# 7.2 Rodar migrations
bundle exec rails db:migrate

# 7.3 Compilar assets
pnpm build

# 7.4 Rodar linters
bundle exec rubocop -a
pnpm eslint:fix

# 7.5 Rodar specs
bundle exec rspec
pnpm test

# 7.6 Subir servidor local
overmind start -f Procfile.dev
# Ou: pnpm dev

# 7.7 Testar manualmente (http://localhost:3000)
# - Login funciona?
# - Pipeline/Kanban aparece?
# - Drag & drop funciona?
# - Logos customizados OK?
```

**Checklist de Testes Locais**:
- [ ] Login/Logout
- [ ] Dashboard carrega
- [ ] Pipeline/Kanban no menu
- [ ] Drag & drop de conversas
- [ ] Mudança de stage persiste
- [ ] Logos customizados
- [ ] Console sem erros (F12)
- [ ] Specs passando

**Se algo falhar**, investigar e corrigir antes de prosseguir!

---

## 🚢 ETAPA 8: Deploy no Staging

⚠️ **NUNCA pule esta etapa!** Staging salva você de bugs em produção.

```bash
# 8.1 Push branch de teste
git push origin test/sync-$(date +%Y%m%d)

# 8.2 SSH no servidor staging
ssh root@seu-servidor

# 8.3 Ir para diretório staging
cd ~/chatwoot-staging

# 8.4 Fetch e checkout no branch de teste
git fetch origin
git checkout test/sync-$(date +%Y%m%d)

# 8.5 Rebuild imagem Docker
docker build -t ghcr.io/juniorbra/chatwoot:staging-sync .

# 8.6 Deploy da stack
docker stack deploy -c docker-compose.swarm.yaml chatwoot-staging

# 8.7 Aguardar serviços subirem (30-60 segundos)
watch -n 2 'docker service ls | grep staging'
# Aguardar até aparecer 1/1 em REPLICAS

# 8.8 Rodar migrations
docker exec -it $(docker ps -q -f name=chatwoot-staging.*rails) \
  bundle exec rails db:migrate RAILS_ENV=staging

# 8.9 Ver logs para erros
docker logs --tail 100 $(docker ps -q -f name=chatwoot-staging.*rails) | grep -i error

# 8.10 Testar acesso
# Abrir no navegador: https://staging.botvance.com.br
```

**Checklist de Testes no Staging**:
- [ ] ✅ Login/logout funciona
- [ ] ✅ Pipeline/Kanban aparece no menu
- [ ] ✅ Drag & drop de conversas funciona
- [ ] ✅ Mudança de stage persiste após reload
- [ ] ✅ Logos customizados aparecem
- [ ] ✅ Criar nova conversa funciona
- [ ] ✅ Enviar/receber mensagens funciona
- [ ] ✅ Console do browser sem erros (F12)
- [ ] ✅ Performance <3 segundos

**Status**:
- [ ] Deploy no staging concluído: `______` (data)
- [ ] Aguardar **3-7 dias** para monitoramento

---

## 📊 ETAPA 9: Monitorar Staging (3-7 dias)

### Checklist Diário

**Dia 1** (______):
- [ ] Acessar staging.botvance.com.br
- [ ] Testar funcionalidades críticas
- [ ] Ver logs: `docker logs --tail 50 $(docker ps -q -f name=staging.*rails) | grep -i error`
- [ ] Performance OK

**Dia 2** (______):
- [ ] Acessar staging.botvance.com.br
- [ ] Testar funcionalidades críticas
- [ ] Ver logs
- [ ] Performance OK

**Dia 3** (______):
- [ ] Acessar staging.botvance.com.br
- [ ] Testar funcionalidades críticas
- [ ] Ver logs
- [ ] Performance OK

**Dia 4-7** (opcional, se mudança grande):
- [ ] Cliente piloto testou
- [ ] Feedback positivo
- [ ] Sem erros reportados

### Comandos Úteis para Monitoramento

```bash
# Ver logs em tempo real
ssh root@seu-servidor
docker logs -f $(docker ps -q -f name=chatwoot-staging.*rails)

# Ver erros das últimas 24h
docker logs --since 24h $(docker ps -q -f name=chatwoot-staging.*rails) | grep -i error

# Ver uso de recursos
docker stats $(docker ps -q -f name=chatwoot-staging)

# Ver status dos serviços
docker service ls | grep staging
```

**Decisão após monitoramento**:
- [ ] ✅ TUDO OK → Prosseguir para ETAPA 10
- [ ] ❌ PROBLEMAS → Corrigir, testar novamente, voltar para ETAPA 7

---

## ✅ ETAPA 10: Merge Final em Produção

⚠️ **Só execute se TODOS os testes passaram!**

```bash
# 10.1 Voltar para repositório local
cd ~/projects/chatwoot

# 10.2 Checkout em feature/kanban-crm
git checkout feature/kanban-crm

# 10.3 Garantir que está atualizado
git pull origin feature/kanban-crm

# 10.4 Mergear branch de teste
SYNC_BRANCH="test/sync-$(date +%Y%m%d)"
UPSTREAM_VERSION="v4.X.X"  # ← SUBSTITUIR pela versão real!

git merge $SYNC_BRANCH -m "chore: sync with Chatwoot $UPSTREAM_VERSION

Merged upstream changes from Chatwoot $UPSTREAM_VERSION.
Tested for 7 days in staging with no issues.
No breaking changes affecting Pipeline/Kanban.

Changes:
- [listar principais mudanças do upstream]

Custom features verified:
- Pipeline/Kanban CRM working
- Custom branding intact
- PT-BR translations working
- All specs passing

Testing:
- Staging: staging.botvance.com.br
- Duration: 7 days
- Status: ✅ All tests passed

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Status**:
- [ ] ✅ Merge em feature/kanban-crm concluído

---

## 🏷️ ETAPA 11: Criar Tag de Release

```bash
# 11.1 Definir versão (ajustar conforme necessário)
# Formato: vMAJOR.MINOR.PATCH-botvance.INCREMENT
# Exemplo: v4.10.2-botvance.1

UPSTREAM_VERSION="v4.X.X"  # ← SUBSTITUIR!
BOTVANCE_VERSION="${UPSTREAM_VERSION}-botvance.1"

# 11.2 Criar tag anotada
git tag -a $BOTVANCE_VERSION -m "Sync com Chatwoot $UPSTREAM_VERSION

Base: Chatwoot $UPSTREAM_VERSION oficial
Release date: $(date +%Y-%m-%d)

Features Botvance mantidas:
- Pipeline/Kanban CRM
- Custom branding
- i18n PT-BR

Testing:
- 7 days in staging
- All specs passing
- No breaking changes

Changelog: https://github.com/chatwoot/chatwoot/releases/tag/$UPSTREAM_VERSION"

# 11.3 Ver tag criada
git tag -n5 $BOTVANCE_VERSION

# 11.4 Push do branch + tag
git push origin feature/kanban-crm --tags
```

**Status**:
- [ ] ✅ Tag criada e pushed: `v______-botvance.1`

---

## 🚀 ETAPA 12: Deploy em Produção

⚠️ **Último checkpoint antes de afetar clientes!**

```bash
# 12.1 SSH no servidor de produção
ssh root@seu-servidor-producao

# 12.2 Ir para diretório de produção
cd /chatwoot-custom  # Ou caminho da sua produção

# 12.3 Backup antes do deploy (recomendado)
# Backup do banco
docker exec $(docker ps -q -f name=chatwoot.*postgres) \
  pg_dump -U postgres chatwoot > backup-$(date +%Y%m%d-%H%M%S).sql

# Backup do código
git branch backup-$(date +%Y%m%d-%H%M%S)

# 12.4 Checkout na nova tag
git fetch origin --tags
git checkout v4.X.X-botvance.1  # ← SUBSTITUIR pela tag real!

# 12.5 Rebuild imagem
docker build -t ghcr.io/juniorbra/chatwoot:v4.X.X-botvance.1 .

# 12.6 Deploy da stack de produção
docker stack deploy -c docker-compose.swarm.yaml chatwoot

# 12.7 Aguardar serviços subirem
watch -n 2 'docker service ls | grep chatwoot'
# Aguardar até 1/1 em REPLICAS

# 12.8 Rodar migrations
docker exec -it $(docker ps -q -f name=chatwoot_chatwoot_rails) \
  bundle exec rails db:migrate RAILS_ENV=production

# 12.9 Ver logs
docker logs --tail 100 $(docker ps -q -f name=chatwoot_chatwoot_rails) | grep -i error

# 12.10 Testar acesso
# Abrir: https://botvance.com.br
```

**Checklist Pós-Deploy**:
- [ ] ✅ Site acessível
- [ ] ✅ Login funciona
- [ ] ✅ Pipeline/Kanban OK
- [ ] ✅ Mensagens sendo enviadas/recebidas
- [ ] ✅ Logs sem erros críticos
- [ ] ✅ Performance normal

**Status**:
- [ ] ✅ Deploy em produção concluído: `______` (data/hora)

---

## 🧹 ETAPA 13: Limpeza

```bash
# 13.1 Voltar para repositório local
cd ~/projects/chatwoot

# 13.2 Deletar branch de teste local
git branch -d test/sync-$(date +%Y%m%d)

# 13.3 Deletar branch de teste remoto
git push origin --delete test/sync-$(date +%Y%m%d)

# 13.4 Atualizar changelog (opcional, mas recomendado)
# Editar CHANGELOG.botvance.md com resumo da atualização
```

**Status**:
- [ ] ✅ Limpeza concluída

---

## 🎉 CONCLUÍDO!

**Versão anterior**: `v______-botvance._`
**Versão nova**: `v______-botvance._`
**Data de deploy**: `______`
**Status**: ✅ Produção atualizada com sucesso

---

## 🚨 Plano de Rollback (se algo der errado)

Se após deploy em produção algo quebrar:

```bash
# 1. SSH no servidor
ssh root@seu-servidor-producao

# 2. Voltar para tag anterior
cd /chatwoot-custom
git checkout v4.10.1-botvance.1  # ← TAG ANTERIOR ESTÁVEL

# 3. Rollback das migrations (se necessário)
docker exec -it $(docker ps -q -f name=chatwoot_chatwoot_rails) \
  bundle exec rails db:rollback RAILS_ENV=production STEP=X  # X = número de migrations

# 4. Rebuild e redeploy
docker build -t ghcr.io/juniorbra/chatwoot:rollback .
docker stack deploy -c docker-compose.swarm.yaml chatwoot

# 5. Verificar
docker logs --tail 50 $(docker ps -q -f name=chatwoot_chatwoot_rails)
```

---

## 📚 Referências

- [GIT_WORKFLOW.md](GIT_WORKFLOW.md) - Workflow detalhado
- [STAGING_WORKFLOW.md](STAGING_WORKFLOW.md) - Comandos Docker staging
- [Chatwoot Releases](https://github.com/chatwoot/chatwoot/releases) - Changelog oficial
- [CHANGELOG.botvance.md](../CHANGELOG.botvance.md) - Seu histórico de mudanças

---

*Checklist criado em: 2026-02-05*
*Versão: 1.0*
*Mantenedor: Botvance*
