# Pipeline Stages API

API para gerenciamento de estágios do pipeline (Kanban CRM) no Chatwoot.

## Autenticação

Todas as requisições requerem autenticação via API Access Token:

```
Headers:
  api_access_token: YOUR_API_TOKEN
```

## Base URL

```
https://your-chatwoot-domain.com/api/v1/accounts/{accountId}/pipeline_stages
```

## Endpoints

### 1. Listar todos os estágios

Retorna todos os estágios do pipeline configurados para a conta.

**Endpoint:** `GET /api/v1/accounts/{accountId}/pipeline_stages`

**Exemplo de requisição:**
```bash
curl -X GET \
  'https://chat.adavance.com.br/api/v1/accounts/2/pipeline_stages' \
  -H 'api_access_token: YOUR_API_TOKEN'
```

**Resposta de sucesso (200 OK):**
```json
[
  {
    "id": 1,
    "account_id": 2,
    "name": "Lead",
    "position": 0,
    "color": "#6b7280",
    "created_at": "2026-01-13T15:43:54.000Z",
    "updated_at": "2026-01-13T15:43:54.000Z"
  },
  {
    "id": 2,
    "account_id": 2,
    "name": "Qualification",
    "position": 1,
    "color": "#3b82f6",
    "created_at": "2026-01-13T15:43:54.000Z",
    "updated_at": "2026-01-13T15:43:54.000Z"
  }
]
```

---

### 2. Criar novo estágio

Cria um novo estágio no pipeline.

**Endpoint:** `POST /api/v1/accounts/{accountId}/pipeline_stages`

**Limite:** Máximo de 6 estágios por conta.

**Exemplo de requisição:**
```bash
curl -X POST \
  'https://chat.adavance.com.br/api/v1/accounts/2/pipeline_stages' \
  -H 'api_access_token: YOUR_API_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "pipeline_stage": {
      "name": "Proposta",
      "position": 2,
      "color": "#f59e0b"
    }
  }'
```

**Parâmetros:**
- `name` (string, obrigatório): Nome do estágio (máx. 50 caracteres)
- `position` (integer, obrigatório): Posição do estágio (0-5)
- `color` (string, opcional): Cor no formato hex (#RRGGBB). Padrão: `#3b82f6`

**Resposta de sucesso (201 Created):**
```json
{
  "id": 5,
  "account_id": 2,
  "name": "Proposta",
  "position": 2,
  "color": "#f59e0b",
  "created_at": "2026-01-13T16:30:00.000Z",
  "updated_at": "2026-01-13T16:30:00.000Z"
}
```

**Erro - Limite excedido (422 Unprocessable Entity):**
```json
{
  "error": "Maximum of 6 stages allowed"
}
```

---

### 3. Atualizar estágio

Atualiza um estágio existente.

**Endpoint:** `PATCH /api/v1/accounts/{accountId}/pipeline_stages/{id}`

**Exemplo de requisição:**
```bash
curl -X PATCH \
  'https://chat.adavance.com.br/api/v1/accounts/2/pipeline_stages/5' \
  -H 'api_access_token: YOUR_API_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "pipeline_stage": {
      "name": "Negociação",
      "color": "#8b5cf6"
    }
  }'
```

**Parâmetros:**
- `name` (string, opcional): Novo nome do estágio
- `position` (integer, opcional): Nova posição (0-5)
- `color` (string, opcional): Nova cor (#RRGGBB)

**Resposta de sucesso (200 OK):**
```json
{
  "id": 5,
  "account_id": 2,
  "name": "Negociação",
  "position": 2,
  "color": "#8b5cf6",
  "created_at": "2026-01-13T16:30:00.000Z",
  "updated_at": "2026-01-13T16:35:00.000Z"
}
```

---

### 4. Deletar estágio

Remove um estágio do pipeline.

**Endpoint:** `DELETE /api/v1/accounts/{accountId}/pipeline_stages/{id}`

**Restrição:** Não é possível deletar o último estágio restante.

**Exemplo de requisição:**
```bash
curl -X DELETE \
  'https://chat.adavance.com.br/api/v1/accounts/2/pipeline_stages/5' \
  -H 'api_access_token: YOUR_API_TOKEN'
```

**Resposta de sucesso (204 No Content):**
```
(sem corpo de resposta)
```

**Erro - Último estágio (422 Unprocessable Entity):**
```json
{
  "error": "Cannot delete the last pipeline stage"
}
```

---

### 5. Reordenar estágios

Reordena todos os estágios de uma vez.

**Endpoint:** `POST /api/v1/accounts/{accountId}/pipeline_stages/reorder`

**Exemplo de requisição:**
```bash
curl -X POST \
  'https://chat.adavance.com.br/api/v1/accounts/2/pipeline_stages/reorder' \
  -H 'api_access_token: YOUR_API_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "stages": [
      { "id": 3 },
      { "id": 1 },
      { "id": 2 },
      { "id": 4 }
    ]
  }'
```

**Parâmetros:**
- `stages` (array, obrigatório): Array de objetos com IDs dos estágios na ordem desejada

**Resposta de sucesso (200 OK):**
```json
[
  {
    "id": 3,
    "account_id": 2,
    "name": "Proposta",
    "position": 0,
    "color": "#f59e0b",
    "created_at": "2026-01-13T15:43:54.000Z",
    "updated_at": "2026-01-13T16:40:00.000Z"
  },
  {
    "id": 1,
    "account_id": 2,
    "name": "Lead",
    "position": 1,
    "color": "#6b7280",
    "created_at": "2026-01-13T15:43:54.000Z",
    "updated_at": "2026-01-13T16:40:00.000Z"
  }
]
```

---

## Atualizar estágio de uma conversa

Para mover uma conversa entre estágios do pipeline:

**Endpoint:** `PATCH /api/v1/accounts/{accountId}/pipeline/{conversationDisplayId}/update_stage`

**Exemplo de requisição:**
```bash
curl -X PATCH \
  'https://chat.adavance.com.br/api/v1/accounts/2/pipeline/123/update_stage' \
  -H 'api_access_token: YOUR_API_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "stage": 2
  }'
```

**Parâmetros:**
- `stage` (integer, obrigatório): ID do estágio de destino (ou `null` para remover)

**Resposta de sucesso (200 OK):**
```json
{
  "conversation": {
    "id": 456,
    "display_id": 123,
    "inbox_id": 1,
    "contact_id": 789,
    "status": "open",
    "pipeline_stage": 2,
    "assignee_id": 10,
    "team_id": 5,
    "last_activity_at": 1705167600,
    "contact": {
      "id": 789,
      "name": "João Silva",
      "email": "joao@exemplo.com",
      "phone_number": "+5511999999999",
      "thumbnail": "https://..."
    },
    "inbox": {
      "id": 1,
      "name": "WhatsApp",
      "channel_type": "Channel::Whatsapp"
    }
  }
}
```

---

## Códigos de erro comuns

| Código | Descrição |
|--------|-----------|
| 200 | Sucesso |
| 201 | Criado com sucesso |
| 204 | Deletado com sucesso (sem conteúdo) |
| 401 | Não autorizado (token inválido) |
| 404 | Estágio não encontrado |
| 422 | Dados inválidos ou limite excedido |

---

## Exemplos de automação

### Python - Criar estágios personalizados

```python
import requests

API_TOKEN = "seu_token_aqui"
ACCOUNT_ID = 2
BASE_URL = "https://chat.adavance.com.br/api/v1"

headers = {
    "api_access_token": API_TOKEN,
    "Content-Type": "application/json"
}

# Estágios para um funil de vendas
stages = [
    {"name": "Novo Lead", "color": "#6b7280"},
    {"name": "Contato Inicial", "color": "#3b82f6"},
    {"name": "Qualificação", "color": "#10b981"},
    {"name": "Proposta Enviada", "color": "#f59e0b"},
    {"name": "Negociação", "color": "#8b5cf6"},
    {"name": "Fechamento", "color": "#ef4444"}
]

for index, stage in enumerate(stages):
    payload = {
        "pipeline_stage": {
            "name": stage["name"],
            "position": index,
            "color": stage["color"]
        }
    }

    response = requests.post(
        f"{BASE_URL}/accounts/{ACCOUNT_ID}/pipeline_stages",
        headers=headers,
        json=payload
    )

    if response.status_code == 201:
        print(f"✓ Criado: {stage['name']}")
    else:
        print(f"✗ Erro ao criar {stage['name']}: {response.json()}")
```

### Node.js - Mover conversa entre estágios

```javascript
const axios = require('axios');

const API_TOKEN = 'seu_token_aqui';
const ACCOUNT_ID = 2;
const BASE_URL = 'https://chat.adavance.com.br/api/v1';

async function moveConversationToStage(conversationId, stageId) {
  try {
    const response = await axios.patch(
      `${BASE_URL}/accounts/${ACCOUNT_ID}/pipeline/${conversationId}/update_stage`,
      { stage: stageId },
      {
        headers: {
          'api_access_token': API_TOKEN,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('Conversa movida com sucesso:', response.data);
    return response.data;
  } catch (error) {
    console.error('Erro ao mover conversa:', error.response?.data || error.message);
    throw error;
  }
}

// Exemplo de uso
moveConversationToStage(123, 3);
```

### cURL - Listar e reordenar estágios

```bash
#!/bin/bash

API_TOKEN="seu_token_aqui"
ACCOUNT_ID=2
BASE_URL="https://chat.adavance.com.br/api/v1"

# Listar estágios atuais
echo "Listando estágios atuais:"
curl -s -X GET \
  "${BASE_URL}/accounts/${ACCOUNT_ID}/pipeline_stages" \
  -H "api_access_token: ${API_TOKEN}" | jq '.'

# Reordenar (invertendo ordem)
echo -e "\nReordenando estágios:"
curl -s -X POST \
  "${BASE_URL}/accounts/${ACCOUNT_ID}/pipeline_stages/reorder" \
  -H "api_access_token: ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "stages": [
      {"id": 4},
      {"id": 3},
      {"id": 2},
      {"id": 1}
    ]
  }' | jq '.'
```

---

## Notas importantes

1. **Posições automáticas**: Quando você cria ou deleta estágios, as posições são automaticamente reordenadas para manter a sequência 0, 1, 2, 3, etc.

2. **Limite de estágios**: O sistema permite no máximo 6 estágios por conta.

3. **Proteção de deleção**: Não é possível deletar o último estágio restante. Sempre mantenha pelo menos um estágio.

4. **Formato de cor**: As cores devem estar no formato hexadecimal `#RRGGBB` (ex: `#3b82f6`).

5. **Custom attributes**: O estágio de uma conversa é armazenado em `conversation.custom_attributes.pipeline_stage` como o ID do estágio.

6. **Timestamps**: O sistema registra automaticamente quando o estágio de uma conversa foi atualizado em `custom_attributes.pipeline_updated_at`.

---

## Permissões necessárias

Para usar esta API, você precisa de:
- Token de acesso válido (api_access_token)
- Permissão de "administrator" na conta
- A conta deve ter acesso à feature de pipeline/CRM

---

## Suporte

Para mais informações sobre a API do Chatwoot, consulte a documentação oficial em:
https://www.chatwoot.com/docs/product/channels/api/client-apis
