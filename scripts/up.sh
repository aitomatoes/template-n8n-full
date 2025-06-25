#!/bin/bash
# A linha abaixo faz o script parar imediatamente se algum comando falhar.
set -e

# --- Passo Opcional, mas recomendado: Garantir que a rede compartilhada exista ---
# Cria a rede 'coral-home-net' se ela ainda não existir.
# O '|| true' evita que o script pare com erro se a rede já foi criada antes.
echo "Verificando e criando a rede compartilhada 'coral-home-net'..."
docker network create coral-home-net || true
echo "Rede pronta."
echo ""


# --- Iniciar cada serviço em sua pasta, um por um ---

# Define o diretório raiz do projeto.
# Usamos $(pwd) para executar o comando 'pwd' e capturar sua saída.
ROOT_DIR=$(pwd)/../

echo "Iniciando Redis..."
# Usamos ( ) para criar um subshell.
# O 'cd' funciona dentro do subshell, e '&&' garante que o docker compose só rode se o 'cd' funcionar.
(cd "$ROOT_DIR/redis" && infisical run -- docker compose up -d)

echo "Iniciando n8n..."
(cd "$ROOT_DIR/n8n" && infisical run -- docker compose up -d)

echo "Iniciando Supabase..."
(cd "$ROOT_DIR/supabase" && infisical run -- docker compose up -d)

echo "Iniciando Evolution..."
(cd "$ROOT_DIR/evolution" && infisical run -- docker compose up -d)

echo ""
echo "Todos os serviços foram iniciados com sucesso na rede 'coral-home-net'."