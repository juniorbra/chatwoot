#!/bin/bash
# Script para buildar e fazer push da imagem customizada do Chatwoot

set -e

echo "🐳 Building Chatwoot custom image..."
docker build -f docker/Dockerfile -t hvidigaljr/chatwoot-custom:kanban-crm .

echo ""
echo "✅ Build completed!"
echo ""
echo "📤 Pushing to Docker Hub..."
docker push hvidigaljr/chatwoot-custom:kanban-crm

echo ""
echo "🎉 Done! Image pushed to: hvidigaljr/chatwoot-custom:kanban-crm"
echo ""
echo "📋 Next steps on VPS:"
echo "   1. Update docker-compose.swarm.yaml to use: hvidigaljr/chatwoot-custom:kanban-crm"
echo "   2. Deploy in Portainer"
