# Super Admin no Chatwoot

## Arquitetura

O Chatwoot usa STI (Single Table Inheritance) para SuperAdmin.

### Por que STI?

- Permite autenticação Devise separada (`/super_admin/sign_in`)
- Mantém credenciais unificadas (mesmo email/senha para user e super_admin)
- Suporte nativo do Rails e Devise

### Permissões

⚠️ IMPORTANTE: `User.type` e `AccountUser.role` são INDEPENDENTES:

- `type = "SuperAdmin"` → Acesso ao painel `/super_admin`
- `role = administrator` → Gerencia conta específica

Um usuário pode ser:
- SuperAdmin + Administrator → Painel admin + gerencia conta
- SuperAdmin + Agent → Painel admin + apenas agente
- User + Administrator → Gerencia conta (sem painel)

### Como criar Super Admin
```ruby
# Via Rails Console
user = User.find_by(email: 'email@exemplo.com')
user.type = 'SuperAdmin'
user.save!
```

### Referências

- PR #3830 (2022) - Unificação via STI
- Issues #3061, #3489 - Problemas com tabela separada