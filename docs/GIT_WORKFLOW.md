# Git Workflow - Botvance Chatwoot

Guia completo do fluxo Git para gerenciar o fork Chatwoot com customizações Botvance.

## 📐 Estrutura de Branches

```
upstream/master (Chatwoot oficial - github.com/chatwoot/chatwoot)
    ↓ sync mensal (manual com review)
origin/master (Espelho limpo, NUNCA commitar aqui)
    ↓ merge em branch temporária primeiro
origin/feature/kanban-crm (Produção - código com customizações)
    ↓ deploy via tags vX.X.X-botvance.Y
Produção (servidores dos clientes)
```

### Regras de Ouro

1. **master**: Espelho perfeito do Chatwoot oficial
   - ❌ NUNCA commitar direto
   - ✅ Apenas fast-forward merge do upstream
   - 🎯 Objetivo: Sempre sincronizado com oficial

2. **feature/kanban-crm**: Branch de produção
   - ✅ Todas customizações Botvance
   - ✅ Recebe merges do master após testes
   - ✅ Gera tags de release
   - 🎯 Objetivo: Código production-ready

3. **Branches temporárias**: `test/sync-YYYYMMDD`
   - ✅ Testar merges antes de aplicar no feature/kanban-crm
   - ✅ Deletar após merge bem-sucedido
   - 🎯 Objetivo: Ambiente seguro para testes

---

## 🔄 Workflow Mensal de Sync

### 1. Monitoramento Automático

Todo dia 1 do mês, GitHub Action verifica upstream e cria issue se necessário.

**Localização**: `.github/workflows/upstream-check.yml`

**O que faz**:
- Conta commits atrás do upstream
- Busca última release oficial
- Cria/atualiza issue com checklist completo
- Nível de urgência: 🟢 OK | 🟡 ATENÇÃO | 🔴 CRÍTICO

---

### 2. Revisar Changelog Oficial

Antes de qualquer sync, **sempre ler o changelog** do Chatwoot:

1. Acessar: https://github.com/chatwoot/chatwoot/releases
2. Ler release notes da versão target
3. Identificar:
   - ❌ **Breaking changes** (mudanças que quebram código existente)
   - ⚠️ **Mudanças em arquivos customizados** (conversation.rb, routes.rb, etc.)
   - ✅ **Features novas** que podem conflitar com Pipeline/Kanban
   - 🔒 **Security fixes** (prioridade máxima!)

**Exemplo de breaking change**:
```
v4.11.0 - BREAKING: Renamed Conversation#status to Conversation#state
```

Se encontrar breaking change que afeta suas customizações, **planejar ajustes ANTES** de fazer sync.

---

### 3. Sync em Branch Temporária

**Por que usar branch temporária?**
- Testa merge sem afetar produção
- Permite testar exaustivamente
- Fácil de descartar se der problema

```bash
# Passo 1: Atualizar master com upstream
git checkout master
git fetch upstream master
git merge upstream/master --ff-only  # Só aceita fast-forward
git push origin master

# Passo 2: Criar branch temporária a partir do feature/kanban-crm
git checkout feature/kanban-crm
git checkout -b test/sync-$(date +%Y%m%d)

# Passo 3: Mergear master na branch temporária
git merge master

# Se houver conflitos, prossiga para próxima seção
```

**O que significa --ff-only?**
- "Fast-forward only" = só aceita merge se master não tiver commits próprios
- Se falhar, significa que master divergiu e precisa investigação

---

### 4. Resolver Conflitos

#### Arquivos que SEMPRE conflitam:

##### 🔧 db/schema.rb (100% de chance de conflito)

**Solução automática**:
```bash
./bin/resolve-schema-conflicts.sh
```

**O que faz**:
1. Aceita versão upstream
2. Roda todas migrations (incluindo customizadas)
3. Regenera schema.rb limpo
4. Adiciona ao commit

**Solução manual** (se script falhar):
```bash
# 1. Aceitar versão deles
git checkout --theirs db/schema.rb

# 2. Rodar migrations
bundle exec rails db:migrate

# 3. Regenerar schema
bundle exec rails db:schema:dump

# 4. Adicionar
git add db/schema.rb
```

##### 🛣️ config/routes.rb (alta chance de conflito)

**Revisar linha por linha manualmente**:
```bash
# Ver conflito
git diff config/routes.rb

# Editar arquivo e resolver
# Manter rotas customizadas do pipeline_stages
```

**Nossas rotas customizadas** (não perder!):
```ruby
resources :pipeline_stages, only: [:index, :create, :update, :destroy]
```

##### 💬 app/models/conversation.rb (média chance)

**Verificar se pipeline_stage não foi afetado**:
```bash
grep -n "pipeline_stage" app/models/conversation.rb
```

Se sumiu, re-adicionar:
```ruby
belongs_to :pipeline_stage, optional: true
```

---

### 5. Testar Exaustivamente

```bash
# 1. Instalar dependências (caso tenham mudado)
bundle install
pnpm install

# 2. Rodar testes automatizados
bundle exec rspec            # Tests Ruby
pnpm test                    # Tests JavaScript
bundle exec rubocop -a       # Lint Ruby (auto-fix)
pnpm eslint:fix              # Lint JS (auto-fix)

# 3. Rodar servidor local
overmind start -f Procfile.dev

# 4. Testar manualmente (critical paths):
#    - Login/Logout
#    - Pipeline/Kanban drag & drop
#    - Custom branding visível
#    - Criação de conversas
#    - Mudança de stage
```

**Checklist de testes manuais**:
- [ ] Login funciona
- [ ] Dashboard carrega
- [ ] Pipeline/Kanban aparece no menu
- [ ] Drag & drop de conversas funciona
- [ ] Logos customizados aparecem
- [ ] Favicons corretos
- [ ] PT-BR funcionando
- [ ] Criação de nova conversa
- [ ] Mudança de stage persiste

---

### 6. Deploy em Staging (SE TIVER)

**Se você não tem staging**, pule para Cliente Piloto.

```bash
# 1. Push branch temporária
git push origin test/sync-$(date +%Y%m%d)

# 2. Deploy em staging
# (comando depende da sua infra)

# 3. Monitorar por 3-7 dias
# - Verificar logs: tail -f log/production.log
# - Testar com cliente piloto
# - Verificar métricas (se tiver)
```

---

### 7. Merge Final (Quando tudo OK)

```bash
# 1. Voltar para feature/kanban-crm
git checkout feature/kanban-crm

# 2. Mergear branch temporária
git merge test/sync-$(date +%Y%m%d) -m "chore: sync with Chatwoot v4.X.X

Merged upstream changes from Chatwoot v4.X.X.
Tested for 7 days in staging with client pilot.
No breaking changes affecting Pipeline/Kanban.

Changes:
- [listar principais mudanças do upstream]

Custom features verified:
- Pipeline/Kanban CRM working
- Custom branding intact
- PT-BR translations working
- All specs passing

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# 3. Criar tag de release
git tag -a v4.X.X-botvance.1 -m "Sync com Chatwoot v4.X.X

Base: Chatwoot v4.X.X oficial
Release date: $(date +%Y-%m-%d)

Features Botvance mantidas:
- Pipeline/Kanban CRM
- Custom branding
- i18n PT-BR

Testing:
- 7 days in staging
- Client pilot validated
- All specs passing"

# 4. Push tudo
git push origin feature/kanban-crm --tags

# 5. Limpar branch temporária
git branch -d test/sync-$(date +%Y%m%d)
git push origin --delete test/sync-$(date +%Y%m%d)  # Se fez push dela
```

---

## 🆕 Workflow de Nova Feature

Quando adicionar nova customização:

```bash
# 1. Criar branch de feature
git checkout -b feature/nova-funcionalidade feature/kanban-crm

# 2. Desenvolver
# ... código aqui ...

# 3. Testar
bundle exec rspec spec/path/to/new_spec.rb
pnpm test

# 4. Commit
git add .
git commit -m "feat: adiciona nova funcionalidade

Descrição detalhada da feature.

Co-Authored-By: Seu Nome <seu@email.com>"

# 5. Mergear em feature/kanban-crm
git checkout feature/kanban-crm
git merge feature/nova-funcionalidade

# 6. Criar tag minor (se for feature significativa)
# Se versão atual é v4.10.1-botvance.1, próxima é:
git tag -a v4.10.1-botvance.2 -m "Adiciona nova funcionalidade"

# 7. Push
git push origin feature/kanban-crm --tags

# 8. Limpar branch
git branch -d feature/nova-funcionalidade
```

---

## 🔥 Workflow de Hotfix Urgente

Quando houver bug em produção:

```bash
# 1. Criar branch de hotfix
git checkout -b hotfix/corrige-bug-critico feature/kanban-crm

# 2. Corrigir bug
# ... código aqui ...

# 3. Testar rapidamente
bundle exec rspec spec/path/to/relevant_spec.rb

# 4. Commit
git add .
git commit -m "fix: corrige bug crítico no pipeline

Bug: [descrever o bug]
Causa: [causa raiz]
Solução: [o que foi feito]

Urgente: necessário deploy imediato.

Co-Authored-By: Seu Nome <seu@email.com>"

# 5. Mergear imediatamente
git checkout feature/kanban-crm
git merge hotfix/corrige-bug-critico --no-ff

# 6. Incrementar patch da tag
# Se versão atual é v4.10.1-botvance.1, próxima é:
git tag -a v4.10.1-botvance.2 -m "Hotfix: corrige bug crítico"

# 7. Deploy ASAP
git push origin feature/kanban-crm --tags

# 8. Limpar
git branch -d hotfix/corrige-bug-critico
```

---

## 🏷️ Versionamento

### Formato: `vMAJOR.MINOR.PATCH-botvance.INCREMENT`

**MAJOR.MINOR.PATCH**: Segue versão upstream do Chatwoot

**INCREMENT**: Customizações Botvance

### Exemplos:

```
v4.10.1-botvance.1  →  Primeira release baseada em Chatwoot 4.10.1
v4.10.1-botvance.2  →  Hotfix ou feature sobre mesma base
v4.10.1-botvance.3  →  Outra feature/fix
v4.11.0-botvance.1  →  Sync para Chatwoot 4.11.0 (reset do increment)
```

### Quando incrementar:

- **MAJOR/MINOR/PATCH**: Só muda quando sincroniza com nova versão upstream
- **INCREMENT**:
  - +1 para cada hotfix
  - +1 para cada feature significativa
  - Reset para 1 quando mudar MAJOR/MINOR/PATCH

---

## 🚨 Troubleshooting

### Problema: "Conflito ao mergear master → feature/kanban-crm"

**Solução**:
```bash
# 1. Verificar quais arquivos conflitaram
git status

# 2. Se for schema.rb:
./bin/resolve-schema-conflicts.sh

# 3. Se for routes.rb ou outros:
# Editar manualmente, resolver conflitos
git add <arquivo-resolvido>

# 4. Continuar merge
git merge --continue
```

### Problema: "Testes falhando após sync"

**Passos**:
```bash
# 1. Ver quais specs falharam
bundle exec rspec --fail-fast

# 2. Investigar o que mudou no upstream que afetou specs
git log upstream/master --grep="test\|spec" --oneline -20

# 3. Opções:
#    a) Adaptar specs para nova realidade do upstream
#    b) Adaptar código customizado para não quebrar
#    c) Se for bug do upstream, aguardar fix oficial
```

### Problema: "Cliente reportando bug após deploy"

**Protocolo**:
```bash
# 1. Verificar se é regressão do upstream ou customização
git log feature/kanban-crm -5 --oneline

# 2. Se for do upstream:
#    - Reportar issue: https://github.com/chatwoot/chatwoot/issues
#    - Considerar rollback temporário

# 3. Se for customização:
#    - Criar hotfix imediato (ver workflow acima)
#    - Deploy v4.X.X-botvance.Y+1

# 4. Rollback rápido se necessário:
git checkout v4.10.1-botvance.1  # Versão anterior estável
# Deploy da tag antiga
```

### Problema: "Perdi commits do master acidentalmente"

**Recuperação**:
```bash
# 1. Verificar reflog (histórico de tudo que fez)
git reflog

# 2. Encontrar commit perdido
# Output exemplo: abc1234 HEAD@{5}: commit: meu commit perdido

# 3. Recuperar
git cherry-pick abc1234

# 4. Ou voltar master para aquele ponto
git reset --hard abc1234

# 5. Se tiver backup bundle:
git clone ~/chatwoot-backup-20260205.bundle chatwoot-recovered
```

---

## 📚 Referências

- [CHANGELOG.botvance.md](../CHANGELOG.botvance.md) - Histórico de customizações
- [Chatwoot Releases](https://github.com/chatwoot/chatwoot/releases) - Releases oficiais
- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/) - Modelo de branching
- [Conventional Commits](https://www.conventionalcommits.org/pt-br/) - Padrão de commits

---

## 📞 Suporte

**Issues customizações**: https://github.com/juniorbra/chatwoot/issues
**Issues upstream**: https://github.com/chatwoot/chatwoot/issues
**Documentação oficial**: https://www.chatwoot.com/docs

---

*Documentação gerada em: 2026-02-05*
*Última atualização: v4.10.1-botvance.1*
