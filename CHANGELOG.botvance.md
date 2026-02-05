# Changelog Botvance Chatwoot

Todas as mudanças notáveis deste fork serão documentadas aqui.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/spec/v2.0.0.html).

## [4.10.1-botvance.1] - 2026-02-05

### Base
- Chatwoot v4.10.1 (oficial)

### Adicionado
- 🎯 **Pipeline/Kanban CRM completo** com stages configuráveis
  - Dashboard Kanban visual com drag & drop
  - Gestão de leads através de stages customizáveis
  - API REST completa para gerenciamento de stages

- 🎨 **Custom Branding Habilitado** na Community Edition
  - Upload de logos personalizados
  - Favicons customizados (16x16, 32x32, 96x96, 144x144, 150x150, 310x310)
  - Manifesto personalizado para PWA
  - Habilitado `custom_branding` no Super Admin

- 🌐 **Internacionalização Completa**
  - Traduções PT-BR para todas features do Pipeline
  - Suporte i18n para stages configuráveis

- 📝 **Documentação API**
  - [docs/api/SUPER_ADMIN.md](docs/api/SUPER_ADMIN.md) - Endpoints de Super Admin
  - Exemplos práticos de uso da API Pipeline

### Modificado
- **app/models/super_admin.rb** - Habilitado custom_branding na community edition
- **config/routes.rb** - Adicionadas rotas para pipeline_stages API
- **app/models/conversation.rb** - Suporte a pipeline_stage
- **app/javascript/** - Componentes Vue para Kanban/Pipeline

### Técnico
- **37 commits** customizados sobre Chatwoot v4.10.1
- **~4.000 linhas** adicionadas
- **3 migrations** customizadas para pipeline_stages
- **Specs completas**:
  - `spec/controllers/api/v1/accounts/pipeline_controller_spec.rb`
  - `spec/models/pipeline_stage_spec.rb`
  - `spec/requests/api/v1/accounts/pipeline_stages_spec.rb`

### Arquivos Principais Modificados
```
app/
  ├── models/
  │   ├── super_admin.rb (custom_branding habilitado)
  │   ├── pipeline_stage.rb (novo modelo)
  │   └── conversation.rb (suporte pipeline_stage)
  ├── controllers/api/v1/accounts/
  │   └── pipeline_controller.rb (novo controller)
  └── javascript/
      └── dashboard/
          ├── routes/dashboard/conversation/pipeline/ (novos componentes)
          └── i18n/locale/pt_BR/ (traduções)

config/
  └── routes.rb (rotas pipeline_stages)

db/
  ├── migrate/ (3 migrations customizadas)
  └── schema.rb (atualizado)

docs/
  └── api/SUPER_ADMIN.md (novo)

public/
  ├── brand-assets/ (logos Botvance)
  ├── favicon*.png (favicons customizados)
  └── manifest.json (PWA customizado)

spec/
  ├── controllers/api/v1/accounts/pipeline_controller_spec.rb
  ├── models/pipeline_stage_spec.rb
  ├── requests/api/v1/accounts/pipeline_stages_spec.rb
  └── factories/pipeline_stages.rb
```

### Integrações
- ✅ Compatível com Docker Swarm
- ✅ Deploy via Portainer
- ✅ CI/CD com GitHub Actions customizado

---

## Como Atualizar

### Para Desenvolvedores

```bash
# 1. Atualizar branch
git fetch origin feature/kanban-crm
git pull origin feature/kanban-crm

# 2. Instalar dependências
bundle install
pnpm install

# 3. Rodar migrations
bundle exec rails db:migrate

# 4. Rodar testes
bundle exec rspec
pnpm test
```

### Para Deploy

```bash
# 1. Fazer backup do banco
pg_dump chatwoot_production > backup-$(date +%Y%m%d).sql

# 2. Pull da tag específica
git fetch origin
git checkout v4.10.1-botvance.1

# 3. Build e deploy
docker-compose build
docker-compose up -d

# 4. Rodar migrations
docker-compose exec web bundle exec rails db:migrate
```

---

## Roadmap

### Próximas Versões
- [ ] v4.10.1-botvance.2 - Melhorias UI/UX do Kanban
- [ ] v4.11.0-botvance.1 - Sync com Chatwoot v4.11.0 (quando lançar)
- [ ] Automações baseadas em mudança de stage
- [ ] Relatórios de conversão por pipeline
- [ ] Webhooks para eventos de pipeline

---

## Suporte

Para issues relacionadas às customizações Botvance:
- **Repositório**: https://github.com/juniorbra/chatwoot
- **Branch principal**: feature/kanban-crm

Para issues do Chatwoot oficial:
- **Upstream**: https://github.com/chatwoot/chatwoot
- **Documentação**: https://www.chatwoot.com/docs

---

## Licença

Este fork mantém a licença MIT do Chatwoot original.
Customizações Botvance © 2026 Botvance.
