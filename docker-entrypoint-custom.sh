#!/bin/sh
set -e

echo "🏢 Verificando configuração Enterprise..."

if bundle exec rake enterprise:verify 2>&1 | grep -q "DESATIVADO"; then
    echo "⚙️ Ativando Enterprise..."
    bundle exec rake enterprise:bootstrap
else
    echo "✅ Enterprise já está ativo"
fi

exec docker/entrypoints/rails.sh "$@"
