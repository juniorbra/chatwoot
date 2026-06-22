# 🆘 SOS — Reversão de Emergência (Chatwoot + agente_omnichat)

> **Objetivo:** voltar a produção ao último estado bom conhecido o mais rápido possível.
> **Quando usar:** após um deploy, se o Chatwoot ou o agente (Túlio) ficar instável, fora do ar, com erro de boot, comportamento errado, ou clientes reclamando.
> **Princípio:** primeiro **estabilizar** (reverter a imagem), depois investigar com calma.

**Última atualização:** 2026-06-22 · **Mantenedor:** Hilton (juniorbra)

---

## 0. Decisão rápida (30 segundos)

1. O que quebrou? → **Chatwoot** (atendimento/inbox/kanban) ou **agente_omnichat** (respostas automáticas do Túlio)? Os dois rodam em **Swarms diferentes** (ver tabela abaixo).
2. É erro de **aplicação** (imagem nova ruim)? → siga o rollback da imagem (§2 / §3). É o caso mais comum e o mais rápido de reverter.
3. É erro de **banco/dados**? → rollback de imagem **não** resolve sozinho (ver ⚠️ §4). Estabilize a imagem e chame ajuda antes de mexer em dados.

---

## 1. Mapa de produção (verificado em 2026-06-22)

| Serviço | Portainer (host) | Stack / serviços | Imagem em produção |
|---|---|---|---|
| **Chatwoot** | `https://painel.adavance.com.br` | `chatwoot_rails`, `chatwoot_sidekiq` (+ `chatwoot_postgres`, `chatwoot_redis`) | `ghcr.io/juniorbra/chatwoot:kanban-crm` |
| **agente_omnichat** | `https://painel.manager01.botvance.com.br` | `agente-omnichat_agent` (worker02) | `ghcr.io/juniorbra/agente-omnichat:latest` |

**As tags `:kanban-crm` e `:latest` são MUTÁVEIS** — um deploy/CI pode sobrescrevê-las. Por isso existem as tags imutáveis de rollback abaixo.

### Ponto de retorno conhecido-bom (snapshot 2026-06-22)

| Imagem | Tag de rollback (imutável) | Digest |
|---|---|---|
| Chatwoot | `ghcr.io/juniorbra/chatwoot:rollback-2026-06-22` | `sha256:fff15b4894da1146a369066c23ca8f8a24187ac38ec28194126dd1a9a6bb992a` |
| agente_omnichat | `ghcr.io/juniorbra/agente-omnichat:rollback-2026-06-22` | `sha256:29c42cc8041ecc1e948784f30a8dfe0f264fd522f281d3268758757873c76064` |

> Se a tag de rollback sumir ou estiver suspeita, você ainda pode reverter usando o **digest** direto: `ghcr.io/juniorbra/chatwoot@sha256:fff15b48...` (a imagem por digest é imutável e sempre a mesma).

---

## 2. Reverter o CHATWOOT

### Via Portainer (recomendado, sob pressão)
1. Acesse `https://painel.adavance.com.br` → environment **primary** → **Services**.
2. Para **`chatwoot_chatwoot_rails`**: clique no serviço → campo **Image** → troque para:
   ```
   ghcr.io/juniorbra/chatwoot:rollback-2026-06-22
   ```
   → marque **Pull latest image** (ou *Re-pull image*) → **Update the service**.
3. Repita para **`chatwoot_chatwoot_sidekiq`** (mesma imagem).
4. Acompanhe em **Service logs** / **Tasks** até o estado `running`.

### Via stack file (se o deploy é por stack)
- Edite o stack do Chatwoot, troque `image:` dos dois serviços para `:rollback-2026-06-22`, **Update the stack**.

### Confirmar que voltou
- O Swarm deve estar rodando o digest `fff15b48…`. Sintoma resolvido + `https://omnichat.botvance.com.br` respondendo + login OK.

---

## 3. Reverter o agente_omnichat (Túlio)

### Via Portainer
1. Acesse `https://painel.manager01.botvance.com.br` → environment **primary** → **Services**.
2. Serviço **`agente-omnichat_agent`** → campo **Image** → troque para:
   ```
   ghcr.io/juniorbra/agente-omnichat:rollback-2026-06-22
   ```
   → **Pull latest image** → **Update the service**.
3. Acompanhe **logs** até `running`. O agente roda no **worker02** (`node.labels.model==small`).

### Confirmar que voltou
- Digest rodando deve ser `29c42cc8…`. Mande uma mensagem de teste no WhatsApp e veja se o Túlio responde normal.

---

## 4. ⚠️ Ressalvas críticas

- **Banco não reverte com a imagem.** O Chatwoot roda migrations no boot (`db:chatwoot_prepare`). Reverter a imagem **não desfaz** migrations já aplicadas.
  - Migrations **aditivas/retrocompatíveis** (ex.: adicionar coluna `description` em `pipeline_stages`) são **seguras**: a imagem antiga ignora a coluna nova. Rollback de imagem resolve.
  - Migrations **destrutivas** (drop/rename de coluna, mudança de tipo): rollback de imagem **pode não bastar** → estabilize e restaure backup do Postgres antes de mexer.
- **Data stores compartilhados:** o Postgres/Redis do Chatwoot são compartilhados com staging; o Swarm do `manager01` é **compartilhado** com ~25 outros serviços (n8n, waha, etc.). Cuidado ao reiniciar nós/recursos — pode afetar terceiros.
- **Hack Enterprise:** após upgrade, o plano enterprise pode cair ~24h depois (job diário que pinga o hub). Ver `docs/UPGRADE_4.15.1_PLAN.md` (fix: `extra_hosts` apontando o hub para 127.0.0.1).

---

## 5. Antes de CADA deploy: criar um novo ponto de rollback

Rode isto **antes** de subir versão nova (do WSL; `crane` já instalado em `~/.local/bin`):

```bash
export PATH="$HOME/.local/bin:$PATH"
set -a; . ~/.bws-env; set +a   # carrega BWS_ACCESS_TOKEN

# login no ghcr (PAT clássico com write:packages — bws key GITHUB_TOKEN)
GH=$(bws secret get dde74657-57a9-4ac6-9743-b4710139a437 | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>process.stdout.write(JSON.parse(s).value))')
printf '%s' "$GH" | crane auth login ghcr.io -u juniorbra --password-stdin; unset GH

DATA=$(date +%Y-%m-%d)   # ou defina manualmente

# 1) descubra o digest REALMENTE rodando (via Portainer) e troque abaixo:
#    Chatwoot:  GET painel.adavance.com.br  /api/endpoints/1/docker/services  -> chatwoot_chatwoot_rails .Image
#    Agente:    GET painel.manager01.botvance.com.br /api/endpoints/1/docker/services -> agente-omnichat_agent .Image

# 2) fixe a tag imutável apontando para esse digest:
crane tag ghcr.io/juniorbra/chatwoot@sha256:<DIGEST_CHATWOOT>        rollback-$DATA
crane tag ghcr.io/juniorbra/agente-omnichat@sha256:<DIGEST_AGENTE>  rollback-$DATA

# 3) confirme:
crane digest ghcr.io/juniorbra/chatwoot:rollback-$DATA
crane digest ghcr.io/juniorbra/agente-omnichat:rollback-$DATA
```

> `crane tag` é cópia **server-side** no registry: não baixa camadas, não toca na produção, não reinicia nada.

---

## 6. Credenciais (no Bitwarden Secrets / bws — projeto `de61d9a2-…`)

| Para quê | bws key | UUID |
|---|---|---|
| Portainer **adavance** (Chatwoot) | `PTR_ADAVANCE_TOKEN` | `1f81edbf-2ad1-4dfd-8d94-b46c004ae278` |
| Portainer **manager01** (agente) | `PTR_BOTVANCE_TOKEN` | `b906719f-cb20-4895-abcc-b46c004a6a8d` |
| GitHub PAT (ghcr, `write:packages`) | `GITHUB_TOKEN` | `dde74657-57a9-4ac6-9743-b4710139a437` |

> Os UUIDs são identificadores, não segredos — para ler o valor é preciso o `BWS_ACCESS_TOKEN` (em `~/.bws-env`, chmod 600). Nunca cole valores de token neste documento.
> Token de API do Portainer costuma ser admin — use com cuidado; cada token é válido só no seu host (não reusar entre adavance e manager01).

---

## 7. Checklist pós-incidente
- [ ] Produção estável (imagem revertida, serviços `running`).
- [ ] Clientes confirmando normalidade (Chatwoot abre; Túlio responde).
- [ ] Anotar o que quebrou e por quê (antes de tentar de novo).
- [ ] Se a tag mutável (`:kanban-crm`/`:latest`) foi sobrescrita por imagem ruim, **não** rebuildar por cima até entender a causa.
