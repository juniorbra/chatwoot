🔹 Pipeline Stages (Configuração dos Estágios)
1. Listar todos os estágios

GET /api/v1/accounts/:account_id/pipeline_stages
2. Criar novo estágio

POST /api/v1/accounts/:account_id/pipeline_stages
Body:


{
  "pipeline_stage": {
    "name": "Qualificado",
    "position": 1,
    "color": "#10B981"
  }
}
3. Atualizar estágio

PATCH /api/v1/accounts/:account_id/pipeline_stages/:id
PUT /api/v1/accounts/:account_id/pipeline_stages/:id
Body:


{
  "pipeline_stage": {
    "name": "Novo nome",
    "color": "#EF4444"
  }
}
4. Deletar estágio

DELETE /api/v1/accounts/:account_id/pipeline_stages/:id
Nota: Não pode deletar se for o último estágio

5. Reordenar estágios

POST /api/v1/accounts/:account_id/pipeline_stages/reorder
Body:


{
  "stages": [
    { "id": 1, "position": 0 },
    { "id": 3, "position": 1 },
    { "id": 2, "position": 2 }
  ]
}
📝 Observações:
Limite máximo: Existe um limite de estágios definido em PipelineStage::MAX_STAGES
Autenticação: Todos os endpoints requerem autenticação via API token
Formato: Todos os endpoints retornam JSON
Permissões: Operações de stages requerem permissão de update na conta

Existem duas formas de alterar o pipeline stage de uma conversa:

1. Via Interface (Kanban Board)
Acesse /accounts/:accountId/pipeline no dashboard. Lá você verá o quadro Kanban com as colunas representando cada stage. Basta arrastar e soltar o card da conversa de uma coluna para outra.

2. Via API
Faça um PATCH no endpoint de update_stage:


PATCH /api/v1/accounts/:account_id/pipeline/:conversation_display_id/update_stage
Com o body:


{
  "stage": 2
}
Onde stage é o ID do PipelineStage para onde você quer mover a conversa. Para remover de qualquer stage, envie "stage": null.

Exemplo com curl:


curl -X PATCH \
  "https://seu-chatwoot.com/api/v1/accounts/1/pipeline/42/update_stage" \
  -H "api_access_token: SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"stage": 3}'
Observações importantes
O pipeline stage é armazenado nos custom_attributes da conversa (não do contato). O campo é pipeline_stage.
Para listar os stages disponíveis: GET /api/v1/accounts/:account_id/pipeline_stages
Os stages são configuráveis em Settings > Pipeline Stages (apenas administradores).
Máximo de 6 stages por account.
Cada mudança registra pipeline_updated_at e pipeline_updated_by nos custom_attributes da conversa.
Quer que eu mostre mais detalhes sobre algum desses fluxos?