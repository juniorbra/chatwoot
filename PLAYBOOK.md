# 📖 Playbook Botvance Chatwoot

Guia executável rápido para operações comuns. Copie e cole os comandos.

---

## 🎯 Setup Inicial (FEITO!)

✅ Backup completo criado
✅ Master limpo e sincronizado
✅ CHANGELOG.botvance.md criado
✅ Tag v4.10.1-botvance.1 criada
✅ GitHub Actions configurado (alerta mensal)
✅ Script de resolução de conflitos criado
✅ Documentação completa

---

## 📅 Checklist Mensal (Todo dia 1)

### 1. Verificar Issue Automática

GitHub Actions cria automaticamente issue se estiver >20 commits atrás.

**Onde ver**: https://github.com/juniorbra/chatwoot/issues

**Se não tiver issue**: Está OK, nada a fazer.

**Se tiver issue**: Seguir passos abaixo.

---

## 🔄 Playbook: Sync com Upstream

Execute este playbook quando precisar sincronizar com Chatwoot oficial.

### Preparação (5 min)

```bash
# 1. Ler changelog oficial
# Abrir: https://github.com/chatwoot/chatwoot/releases
# Identificar breaking changes

# 2. Avisar time
# Mandar mensagem: "Vou fazer sync upstream hoje, possível deploy amanhã"

# 3. Criar backup (paranoia++)
git tag backup/pre-sync-$(date +%Y%m%d)
git push origin backup/pre-sync-$(date +%Y%m%d)
```

### Sync do Master (2 min)

```bash
# 1. Ir para master
cd ~/projects/chatwoot
git checkout master

# 2. Buscar upstream
git fetch upstream master

# 3. Mergear (fast-forward only)
git merge upstream/master --ff-only

# Se falhar aqui, PARE e investigue:
# git log master --not --remotes=upstream/master

# 4. Push
git push origin master
```

### Teste em Branch Temporária (10-30 min)

```bash
# 1. Criar branch temporária
git checkout feature/kanban-crm
git pull origin feature/kanban-crm
git checkout -b test/sync-$(date +%Y%m%d)

# 2. Mergear master
git merge master

# 3. Se houver conflitos:
#    a) schema.rb (quase certeza):
./bin/resolve-schema-conflicts.sh

#    b) routes.rb (provável):
#       Editar manualmente, manter linhas do pipeline_stages
git add config/routes.rb

#    c) Outros arquivos:
#       Resolver manualmente
git add <arquivo>

# 4. Continuar merge (se houve conflitos)
git merge --continue

# 5. Instalar dependências
bundle install
pnpm install

# 6. Rodar migrations
bundle exec rails db:migrate

# 7. Rodar testes
bundle exec rspec
pnpm test

# 8. Corrigir linters
bundle exec rubocop -a
pnpm eslint:fix

# 9. Commitar correções de lint (se houver)
git add .
git commit -m "chore: fix linting after upstream sync"
```

### Teste Manual (15 min)

```bash
# 1. Subir servidor local
overmind start -f Procfile.dev

# 2. Abrir browser: http://localhost:3000

# 3. Testar checklist:
# [ ] Login funciona
# [ ] Dashboard carrega
# [ ] Pipeline/Kanban aparece no menu
# [ ] Drag & drop funciona
# [ ] Logos Botvance aparecem
# [ ] PT-BR funcionando

# Se tudo OK, continuar
# Se algo quebrou, investigar e corrigir
```

### Deploy em Staging (3-7 dias) 🚨 VOCÊ NÃO TEM AINDA

**ATENÇÃO**: Você não tem staging configurado. Opções:

**Opção A**: Configurar staging agora (ver `docs/STAGING_SETUP.md`)

**Opção B**: Pular staging e usar cliente piloto diretamente ⚠️ RISCO

Se pular staging:

```bash
# 1. Mergear direto no feature/kanban-crm
git checkout feature/kanban-crm
git merge test/sync-$(date +%Y%m%d) -m "chore: sync with Chatwoot vX.X.X

Merged upstream Chatwoot vX.X.X.
Tested locally, all specs passing.

WARNING: No staging environment available.
Deploying directly to production with client pilot monitoring.

Changes from upstream:
- [listar principais mudanças]

Custom features verified:
- Pipeline/Kanban working
- Custom branding intact
- PT-BR working

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# 2. Criar tag
git tag -a vX.X.X-botvance.1 -m "Sync com Chatwoot vX.X.X"

# 3. Push
git push origin feature/kanban-crm --tags

# 4. Deploy em produção
# ... seu processo de deploy aqui ...

# 5. Monitorar MUITO DE PERTO por 24-48h
# - Logs: tail -f log/production.log
# - Cliente piloto: perguntar se está tudo OK
# - Métricas: verificar se erros aumentaram
```

### Merge Final (se usou staging)

```bash
# Depois de testar em staging por 3-7 dias:

# 1. Mergear no feature/kanban-crm
git checkout feature/kanban-crm
git merge test/sync-$(date +%Y%m%d) -m "chore: sync with Chatwoot vX.X.X

Tested in staging for 7 days.
Client pilot validated successfully.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# 2. Criar tag
git tag -a vX.X.X-botvance.1 -m "Sync com Chatwoot vX.X.X"

# 3. Push
git push origin feature/kanban-crm --tags

# 4. Limpar branch temporária
git branch -d test/sync-$(date +%Y%m%d)

# 5. Deploy em produção
# ... seu processo de deploy aqui ...
```

### Atualizar Documentação

```bash
# 1. Atualizar CHANGELOG.botvance.md
nano CHANGELOG.botvance.md

# Adicionar nova seção:
## [vX.X.X-botvance.1] - $(date +%Y-%m-%d)

### Base
- Chatwoot vX.X.X (oficial)

### Atualizado
- Sincronizado com Chatwoot vX.X.X
- [Listar mudanças relevantes do upstream]

### Customizações Mantidas
- Pipeline/Kanban CRM
- Custom Branding
- i18n PT-BR

# 2. Commitar
git add CHANGELOG.botvance.md
git commit -m "docs: update changelog for vX.X.X-botvance.1"
git push origin feature/kanban-crm
```

---

## 🆕 Playbook: Nova Feature Customizada

Quando adicionar funcionalidade própria:

```bash
# 1. Criar branch
git checkout feature/kanban-crm
git pull origin feature/kanban-crm
git checkout -b feature/nome-da-feature

# 2. Desenvolver
# ... código aqui ...

# 3. Testar
bundle exec rspec spec/caminho/do/spec.rb
pnpm test

# 4. Commitar
git add .
git commit -m "feat: adiciona nome da feature

Descrição detalhada.

Co-Authored-By: Seu Nome <seu@email.com>"

# 5. Mergear
git checkout feature/kanban-crm
git merge feature/nome-da-feature

# 6. Tag (incrementar patch)
# Se versão atual é v4.10.1-botvance.1:
git tag -a v4.10.1-botvance.2 -m "Adiciona nome da feature"

# 7. Push
git push origin feature/kanban-crm --tags

# 8. Limpar
git branch -d feature/nome-da-feature

# 9. Deploy
# ... seu processo de deploy aqui ...

# 10. Atualizar CHANGELOG
# (similar ao passo anterior)
```

---

## 🔥 Playbook: Hotfix Urgente

Bug crítico em produção:

```bash
# 1. Criar branch de hotfix
git checkout feature/kanban-crm
git pull origin feature/kanban-crm
git checkout -b hotfix/nome-do-bug

# 2. Corrigir
# ... código aqui ...

# 3. Testar rapidamente
bundle exec rspec spec/caminho/relevante.rb

# 4. Commitar
git add .
git commit -m "fix: corrige nome do bug

Bug: [descrição]
Causa: [causa raiz]
Solução: [o que foi feito]

Urgente: necessário deploy imediato.

Co-Authored-By: Seu Nome <seu@email.com>"

# 5. Mergear
git checkout feature/kanban-crm
git merge hotfix/nome-do-bug --no-ff

# 6. Tag (incrementar)
# Se v4.10.1-botvance.1, próxima é:
git tag -a v4.10.1-botvance.2 -m "Hotfix: nome do bug"

# 7. Push
git push origin feature/kanban-crm --tags

# 8. Deploy IMEDIATO
# ... seu processo de deploy aqui ...

# 9. Monitorar
tail -f log/production.log

# 10. Limpar
git branch -d hotfix/nome-do-bug

# 11. Avisar stakeholders
# "Hotfix deployado, bug X corrigido"
```

---

## 📊 Playbook: Verificação de Saúde

Execute periodicamente (semanal):

```bash
# 1. Verificar se master está sincronizado
git checkout master
git fetch upstream master
git log master..upstream/master --oneline | wc -l
# Se > 0: master está desatualizado, sincronizar

# 2. Verificar quantos commits atrás do upstream
git log feature/kanban-crm..upstream/master --oneline | wc -l
# Se > 50: urgente sincronizar
# Se 20-50: planejar sync
# Se < 20: OK

# 3. Verificar tamanho do bundle de backup
ls -lh ~/chatwoot-backup-*.bundle
# Se > 500MB: considerar limpar histórico antigo

# 4. Verificar tags
git tag | grep botvance | tail -5
# Conferir se versionamento está consistente

# 5. Verificar GitHub Actions
# Abrir: https://github.com/juniorbra/chatwoot/actions
# Ver se último run foi sucesso
```

---

## 🆘 Playbook: Rollback de Emergência

Algo deu muito errado, precisa voltar:

```bash
# 1. Identificar última versão boa
git tag | grep botvance
# Ex: v4.10.1-botvance.1 estava OK

# 2. Fazer checkout da tag boa
git checkout v4.10.1-botvance.1

# 3. Deploy da versão antiga
# ... seu processo de deploy aqui ...

# 4. Avisar stakeholders
# "Rollback para v4.10.1-botvance.1 devido a [problema]"

# 5. Investigar o que deu errado
git log v4.10.1-botvance.1..v4.10.1-botvance.2 --oneline
git diff v4.10.1-botvance.1 v4.10.1-botvance.2

# 6. Corrigir em branch separada
git checkout -b fix/problema-detectado feature/kanban-crm
# ... corrigir aqui ...

# 7. Quando corrigido, criar nova tag
git tag -a v4.10.1-botvance.3 -m "Fix: problema detectado"

# 8. Deploy da versão corrigida
# ... seu processo de deploy aqui ...
```

---

## 🔧 Playbook: Resolver Conflito Comum

### Conflito em schema.rb

```bash
./bin/resolve-schema-conflicts.sh
# Script resolve automaticamente
```

### Conflito em routes.rb

```bash
# 1. Abrir arquivo
nano config/routes.rb

# 2. Procurar por markers de conflito:
# <<<<<<< HEAD
# ========
# >>>>>>> master

# 3. Manter AMBAS as rotas:
# - As rotas do upstream (novas)
# - As rotas customizadas (pipeline_stages)

# Exemplo de resolução correta:
resources :conversations do
  # ... rotas do upstream ...
end

# Nossa customização (manter!):
resources :pipeline_stages, only: [:index, :create, :update, :destroy]

# 4. Remover markers de conflito

# 5. Salvar

# 6. Adicionar
git add config/routes.rb
```

### Conflito em outro arquivo

```bash
# 1. Ver diff
git diff <arquivo>

# 2. Decidir estratégia:
# a) Aceitar upstream (perdemos customização):
git checkout --theirs <arquivo>

# b) Manter nosso (perdemos mudança upstream):
git checkout --ours <arquivo>

# c) Resolver manualmente (recomendado):
nano <arquivo>
# Editar cuidadosamente

# 3. Adicionar
git add <arquivo>
```

---

## 📚 Referências Rápidas

### Arquivos Importantes

| Arquivo | Descrição |
|---------|-----------|
| `CHANGELOG.botvance.md` | Histórico de customizações |
| `docs/GIT_WORKFLOW.md` | Workflow Git completo |
| `docs/STAGING_SETUP.md` | Como configurar staging |
| `docs/api/SUPER_ADMIN.md` | API Super Admin |
| `bin/resolve-schema-conflicts.sh` | Resolve conflitos schema.rb |
| `.github/workflows/upstream-check.yml` | GitHub Action de alerta |

### Comandos Úteis

```bash
# Ver versão atual
git describe --tags --abbrev=0

# Ver último commit
git log -1 --oneline

# Ver arquivos modificados
git status

# Ver histórico de tags
git tag | grep botvance

# Ver quantos commits atrás do upstream
git fetch upstream && git log --oneline feature/kanban-crm..upstream/master | wc -l

# Buscar em código
grep -r "pipeline_stage" app/

# Ver logs produção
tail -f log/production.log

# Verificar rbenv
rbenv version

# Rodar testes específicos
bundle exec rspec spec/controllers/api/v1/accounts/pipeline_controller_spec.rb

# Rodar migration específica
bundle exec rails db:migrate:status
```

### Links Úteis

- **Seu fork**: https://github.com/juniorbra/chatwoot
- **Upstream**: https://github.com/chatwoot/chatwoot
- **Releases upstream**: https://github.com/chatwoot/chatwoot/releases
- **Issues upstream**: https://github.com/chatwoot/chatwoot/issues
- **Docs Chatwoot**: https://www.chatwoot.com/docs

---

## 🎯 Próximos Passos Recomendados

### Curto Prazo (Esta Semana)

- [ ] Configurar staging environment (docs/STAGING_SETUP.md)
- [ ] Fazer primeiro teste de sync (sem aplicar em produção)
- [ ] Documentar processo de deploy
- [ ] Identificar cliente piloto

### Médio Prazo (Próximas Semanas)

- [ ] Fazer primeiro sync real (quando houver release importante)
- [ ] Validar workflow com time
- [ ] Configurar alertas de erros (Sentry, Bugsnag, etc.)
- [ ] Documentar rollback process

### Longo Prazo (Próximos Meses)

- [ ] Automatizar deploy
- [ ] Configurar CI/CD completo
- [ ] Migrar staging para VPS dedicada
- [ ] Implementar blue-green deployment

---

## 🆘 Contatos de Emergência

**Se algo der muito errado**:

1. **Rollback imediato** (ver playbook acima)
2. **Avisar stakeholders**
3. **Investigar logs**: `tail -f log/production.log`
4. **Buscar ajuda**:
   - Issues do Chatwoot: https://github.com/chatwoot/chatwoot/issues
   - Discord Chatwoot: https://discord.gg/chatwoot

---

*Playbook gerado em: 2026-02-05*
*Versão atual: v4.10.1-botvance.1*
*Última atualização: 2026-02-05*

## ✅ Revisões

| Data | Versão | Mudanças |
|------|--------|----------|
| 2026-02-05 | 1.0 | Criação inicial |

---

**💡 Dica**: Mantenha este playbook aberto enquanto executa operações. Copie e cole os comandos. Documente mudanças conforme aprende.
