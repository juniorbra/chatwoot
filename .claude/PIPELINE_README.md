# Pipeline CRM - Kanban Board para Chatwoot

## 📋 Visão Geral

Sistema de CRM visual com Kanban board para gerenciar conversas como pipeline de vendas.

**Status**: ✅ MVP Completo e Funcional

**Branch**: `feature/kanban-crm`

**Commits**:
- `d43afa7` - Backend foundation
- `afedc6d` - Frontend structure
- `dc102ab` - UI components com drag & drop

---

## 🏗️ Arquitetura

### Backend (Rails)

**Modelo**: `Conversation`
- Armazena estágio em `custom_attributes` JSONB
- Estrutura: `{ "pipeline_stage": "lead", "pipeline_updated_at": "...", "pipeline_updated_by": 123 }`
- Constante: `PIPELINE_STAGES = %w[lead qualification proposal negotiation won lost]`
- Scopes: `with_pipeline_stage(stage)`, `in_pipeline`
- Métodos: `pipeline_stage`, `pipeline_stage=`, `in_pipeline?`

**Controller**: `Api::V1::Accounts::PipelineController`
- `GET /api/v1/accounts/:account_id/pipeline` → Conversas agrupadas
- `PATCH /api/v1/accounts/:account_id/pipeline/:id/update_stage` → Move conversa

**Migração**: `20260112010212_add_pipeline_stage_index.rb`
- Índice btree: `(custom_attributes->>'pipeline_stage')`

**Testes**: 8 specs RSpec (100% passando)
- `spec/controllers/api/v1/accounts/pipeline_controller_spec.rb`

### Frontend (Vue 3)

**Store**: `app/javascript/dashboard/store/modules/pipeline.js`
- State: `conversationsByStage`, `stages`, `uiFlags`
- Actions: `get()`, `updateStage({ conversationId, stage, fromStage })`
- Mutations: `SET_PIPELINE_CONVERSATIONS`, `UPDATE_PIPELINE_CONVERSATION`

**API Client**: `app/javascript/dashboard/api/pipeline.js`
- Wrapper para endpoints do backend

**Componentes**:
```
PipelineView.vue (página principal)
└── PipelineBoard.vue (container)
    └── PipelineColumn.vue (6x colunas draggable)
        └── PipelineCard.vue (card de conversa)
```

**Rota**: `/accounts/:accountId/pipeline`

**Menu**: Sidebar → "Pipeline" (ícone kanban)

---

## 🚀 Como Usar

### 1. Acessar o Pipeline

1. Login no Chatwoot
2. Clicar em "Pipeline" no menu lateral
3. Visualizar 6 colunas: Lead → Qualification → Proposal → Negotiation → Won → Lost

### 2. Adicionar Conversas ao Pipeline

**Via Interface** (futuro):
- Arrastar conversa da inbox para coluna

**Via Console Rails**:
```ruby
# No terminal
bundle exec rails console

# Adicionar conversa existente ao pipeline
conversation = Conversation.first
conversation.pipeline_stage = 'lead'
conversation.save

# Ou criar nova conversa já no pipeline
account = Account.first
inbox = account.inboxes.first
contact = Contact.first

conversation = Conversation.create!(
  account: account,
  inbox: inbox,
  contact: contact,
  contact_inbox: ContactInbox.find_or_create_by(contact: contact, inbox: inbox)
)

conversation.pipeline_stage = 'qualification'
conversation.save
```

### 3. Mover Conversas Entre Estágios

**Drag & Drop**:
- Clicar e segurar um card
- Arrastar para outra coluna
- Soltar para mover

**Via API**:
```bash
curl -X PATCH \
  http://localhost:3000/api/v1/accounts/1/pipeline/123/update_stage \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{"stage": "proposal"}'
```

### 4. Seed com Dados de Exemplo

```bash
# Criar conversas de exemplo no pipeline
bundle exec rake pipeline:seed

# Limpar pipeline
bundle exec rake pipeline:clear
```

---

## 🧪 Testes

### Backend (RSpec)
```bash
# Rodar todos os testes do pipeline
bundle exec rspec spec/controllers/api/v1/accounts/pipeline_controller_spec.rb

# Rodar teste específico
bundle exec rspec spec/controllers/api/v1/accounts/pipeline_controller_spec.rb:70
```

### Frontend (Manual)
1. Acessar `/accounts/1/pipeline`
2. Verificar loading state
3. Verificar colunas vazias se sem dados
4. Seed com `rake pipeline:seed`
5. Refresh da página
6. Arrastar cards entre colunas
7. Verificar atualização no backend

---

## 📊 Estágios do Pipeline

| Estágio | Descrição | Cor Sugerida |
|---------|-----------|--------------|
| **Lead** | Contato inicial, interesse demonstrado | Azul |
| **Qualification** | Lead qualificado, necessidades identificadas | Amarelo |
| **Proposal** | Proposta enviada | Laranja |
| **Negotiation** | Em negociação, ajustes de proposta | Roxo |
| **Won** | Fechado ganho 🎉 | Verde |
| **Lost** | Perdido, motivo registrado | Vermelho |

---

## 🔧 Configuração Técnica

### Dependências
- **Backend**: Rails 7.1.5.2, PostgreSQL
- **Frontend**: Vue 3, Vuex, vuedraggable 4.1.0, Tailwind CSS

### Estrutura de Arquivos

```
Backend:
├── app/models/conversation.rb (linhas 78-231)
├── app/controllers/api/v1/accounts/pipeline_controller.rb
├── config/routes.rb (linhas 151-156)
├── db/migrate/20260112010212_add_pipeline_stage_index.rb
└── spec/controllers/api/v1/accounts/pipeline_controller_spec.rb

Frontend:
├── app/javascript/dashboard/
│   ├── api/pipeline.js
│   ├── store/
│   │   ├── modules/pipeline.js
│   │   └── mutation-types.js (linhas 188-191)
│   ├── routes/dashboard/pipeline/
│   │   ├── pages/PipelineView.vue
│   │   ├── components/
│   │   │   ├── PipelineBoard.vue
│   │   │   ├── PipelineColumn.vue
│   │   │   └── PipelineCard.vue
│   │   └── pipeline.routes.js
│   ├── i18n/locale/en/pipeline.json
│   └── components-next/sidebar/Sidebar.vue (linhas 430-436)
```

---

## 🎯 Próximas Funcionalidades (Roadmap)

### Prioridade Alta
- [ ] Filtros (inbox, team, assignee)
- [ ] Botão para adicionar conversa ao pipeline direto da inbox
- [ ] Notificações toast de sucesso/erro

### Prioridade Média
- [ ] WebSocket real-time updates (ActionCable)
- [ ] Virtual scrolling para performance (>50 cards)
- [ ] Paginação/lazy loading
- [ ] Analytics básicas (conversão por estágio)

### Prioridade Baixa
- [ ] Estágios customizáveis por conta
- [ ] Valor monetário em conversas
- [ ] Histórico de movimentação
- [ ] Automações (mover após X dias)
- [ ] Exportação CSV/PDF

---

## 🐛 Troubleshooting

### Cards não aparecem
1. Verificar se conversas têm `pipeline_stage` definido
2. Rodar `bundle exec rake pipeline:seed`
3. Verificar console do navegador (F12)
4. Verificar logs Rails: `tail -f log/development.log`

### Drag & drop não funciona
1. Verificar se vuedraggable está instalado: `pnpm list vuedraggable`
2. Verificar console para erros JavaScript
3. Verificar se `isUpdating` não está travado em `true`

### Erro ao mover conversa
1. Verificar permissões do usuário (deve ser admin ou agent)
2. Verificar logs Rails para erro no backend
3. Verificar se `display_id` está correto

### Pipeline vazio após seed
1. Verificar se conta tem inbox: `Account.first.inboxes.any?`
2. Rodar `bundle exec rails console` e verificar:
   ```ruby
   Conversation.in_pipeline.count
   Conversation.with_pipeline_stage('lead').count
   ```

---

## 📝 Notas de Desenvolvimento

### Por que JSONB?
- ✅ Sem migração complexa de schema
- ✅ Flexível para customização futura
- ✅ Índices performáticos
- ✅ Compatível com Chatwoot existente

### Por que não tabela separada?
- ❌ Complexidade adicional
- ❌ Joins desnecessários
- ❌ Over-engineering para MVP

### Convenções do Projeto
- Tailwind CSS only (sem CSS customizado)
- Vue 3 Composition API com `<script setup>`
- RuboCop para Ruby (150 chars)
- ESLint para Vue/JS
- i18n obrigatório (sem strings hardcoded)

---

## 👥 Créditos

**Desenvolvido por**: Claude Sonnet 4.5
**Cliente**: Botvance
**Data**: Janeiro 2026
**Versão**: 1.0.0 (MVP)

---

## 📄 Licença

Este código segue a licença do projeto Chatwoot principal.
