#!/bin/bash
# A linha abaixo faz o script parar imediatamente se algum comando falhar.
set -e

# Define o diretório raiz do projeto, assumindo que o script está em uma subpasta.
ROOT_DIR=$(pwd)/../

echo "Parando Supabase..."
# Entra na pasta do serviço e executa o 'down'.
# O '-v' remove os volumes anônimos associados.
# O '--remove-orphans' remove contêineres de serviços que não estão mais no compose.
(cd "$ROOT_DIR/supabase" && infisical run -- docker compose down)

echo "Parando Evolution..."
(cd "$ROOT_DIR/evolution" && infisical run -- docker compose down)

echo "Parando n8n..."
(cd "$ROOT_DIR/n8n" && infisical run -- docker compose down)

echo "Parando Redis..."
(cd "$ROOT_DIR/redis" && infisical run -- docker compose down)

echo ""
echo "Removendo a rede compartilhada..."
# A sintaxe '|| true' garante que o script não falhe se a rede já foi removida.
docker network rm coral-home-net || true
echo "Rede 'coral-home-net' removida (ou já não existia)."

echo "Todos os serviços foram parados e seus contêineres removidos."

