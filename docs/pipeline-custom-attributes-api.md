# Pipeline - Custom Attributes via API

## Endpoints

| Ação | Método | Endpoint |
|------|--------|----------|
| Criar conversa | `POST` | `/api/v1/accounts/{account_id}/conversations` |
| Atualizar conversa | `PATCH` | `/api/v1/accounts/{account_id}/conversations/{display_id}` |
| Definir stage do pipeline | `PATCH` | `/api/v1/accounts/{account_id}/pipeline/{display_id}/update_stage` |

## Autenticação

Todas as requisições precisam do header:

```
api_access_token: SEU_TOKEN
```

O token pode ser obtido em **Configurações > Perfil**.

## Atributos disponíveis

| Label | Key | Tipo |
|-------|-----|------|
| Passageiros | `passageiros` | number |
| Data | `data` | date |
| Horário | `horario` | text |
| Destino | `destino` | text |

> As keys são definidas em **Configurações > Atributos Personalizados**.

## Exemplos

### Criar conversa com atributos

```bash
curl -X POST \
  'https://seu-dominio.com/api/v1/accounts/1/conversations' \
  -H 'api_access_token: SEU_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "contact_id": 123,
    "inbox_id": 1,
    "custom_attributes": {
      "passageiros": 3,
      "data": "2026-02-15T00:00:00.000Z",
      "horario": "14:30",
      "destino": "São Paulo - Guarulhos"
    }
  }'
```

### Atualizar atributos de conversa existente

```bash
curl -X PATCH \
  'https://seu-dominio.com/api/v1/accounts/1/conversations/15' \
  -H 'api_access_token: SEU_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "custom_attributes": {
      "passageiros": 5,
      "destino": "Rio de Janeiro"
    }
  }'
```

> O `PATCH` faz **merge** — só atualiza os campos enviados, não apaga os demais. Para limpar um campo, envie `null`.

### Atribuir conversa a um stage do pipeline

```bash
curl -X PATCH \
  'https://seu-dominio.com/api/v1/accounts/1/pipeline/15/update_stage' \
  -H 'api_access_token: SEU_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{ "stage": "ID_DO_STAGE" }'
```

## Notas

- O `id` no endpoint de conversa é o `display_id` (número visível no card com `#`)
- Datas devem ser enviadas em formato ISO 8601: `yyyy-MM-ddTHH:mm:ss.000Z`
- No pipeline, datas são exibidas como `dd-MM-yyyy`
- Atributos sem valor preenchido não aparecem no card do pipeline
