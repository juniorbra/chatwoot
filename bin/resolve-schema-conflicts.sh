#!/bin/bash
set -e

# Script para resolver conflitos de schema.rb automaticamente
# Uso: ./bin/resolve-schema-conflicts.sh

echo "🔧 Resolvendo conflitos de schema.rb..."

# Verificar se há conflito em schema.rb
if ! git diff --name-only --diff-filter=U | grep -q "db/schema.rb"; then
  echo "✅ Nenhum conflito em schema.rb encontrado."
  exit 0
fi

echo "📝 Conflito detectado em db/schema.rb"

# 1. Aceitar versão upstream do schema.rb (theirs)
# Isso porque vamos regenerar de qualquer forma
echo "   Aceitando versão upstream..."
git checkout --theirs db/schema.rb

# 2. Verificar se rbenv está configurado (necessário para Rails)
if command -v rbenv &> /dev/null; then
  echo "   Inicializando rbenv..."
  eval "$(rbenv init -)"
fi

# 3. Rodar todas as migrations (incluindo customizadas)
echo "   Rodando migrations..."
if ! bundle exec rails db:migrate RAILS_ENV=development; then
  echo "❌ Erro ao rodar migrations!"
  echo "   Verifique manualmente e rode: bundle exec rails db:migrate"
  exit 1
fi

# 4. Regenerar schema.rb limpo
echo "   Regenerando schema.rb..."
bundle exec rails db:schema:dump RAILS_ENV=development

# 5. Adicionar ao commit de merge
echo "   Adicionando schema.rb ao commit..."
git add db/schema.rb

echo ""
echo "✅ schema.rb resolvido e regenerado com sucesso!"
echo ""
echo "Próximos passos:"
echo "  1. Verificar se há outros conflitos: git status"
echo "  2. Resolver conflitos manualmente (se houver)"
echo "  3. Continuar merge: git merge --continue"
echo "  4. Ou fazer commit: git commit -m 'chore: sync with upstream'"
