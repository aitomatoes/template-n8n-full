#!/bin/bash

# --- Configurações ---
N8N_SERVICE_NAME="n8n"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUPS_CLI_DIR="${PROJECT_ROOT}/backups_cli"

HOST_N8N_VOLUME_ROOT_DIR="${PROJECT_ROOT}/n8n"
N8N_VOLUME_PATH_IN_CONTAINER="/home/node/.n8n"

# --- Cores para o terminal ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${YELLOW}Iniciando processo de importação de dados do n8n via CLI...${NC}"
echo -e "${YELLOW}Diretório do Projeto (PROJECT_ROOT): ${PROJECT_ROOT}${NC}"
echo -e "${YELLOW}Caminho da Pasta N8N no Host (HOST_N8N_VOLUME_ROOT_DIR): ${HOST_N8N_VOLUME_ROOT_DIR}${NC}"

# Sanity Check: Verificar se a pasta do volume existe no host
if [ ! -d "$HOST_N8N_VOLUME_ROOT_DIR" ]; then
    echo -e "${RED}Erro: O diretório do volume n8n não foi encontrado no host: ${HOST_N8N_VOLUME_ROOT_DIR}${NC}"
    echo -e "${RED}Certifique-se de que o script está na pasta 'scripts/' e que a pasta 'n8n/' existe no diretório pai.${NC}"
    exit 1
fi


# 1. Verificar se o contêiner n8n está rodando
echo -e "${YELLOW}Verificando se o contêiner '${N8N_SERVICE_NAME}' está rodando...${NC}"
docker inspect -f '{{.State.Running}}' "$N8N_SERVICE_NAME" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro: Contêiner '${N8N_SERVICE_NAME}' não está rodando. Por favor, inicie-o com 'docker-compose up -d' e tente novamente.${NC}"
    exit 1
fi
echo -e "${GREEN}Contêiner '${N8N_SERVICE_NAME}' está rodando.${NC}"

# 2. Selecionar o backup para importar
echo -e "${YELLOW}Exports CLI disponíveis:${NC}"
select_export_dir=$(ls -d "${BACKUPS_CLI_DIR}"/n8n_export_cli_* 2>/dev/null | sort -r)

if [ -z "$select_export_dir" ]; then
    echo -e "${RED}Nenhum export CLI encontrado em ${BACKUPS_CLI_DIR}. Abortando importação.${NC}"
    exit 1
fi

echo "$select_export_dir" | cat -n
echo -e "${YELLOW}Digite o número do export que deseja importar e pressione Enter (ou Ctrl+C para cancelar):${NC}"
read -p "Número do export: " EXPORT_CHOICE

SELECTED_EXPORT_DIR=$(echo "$select_export_dir" | sed -n "${EXPORT_CHOICE}p")

if [ -z "$SELECTED_EXPORT_DIR" ] || [ ! -d "$SELECTED_EXPORT_DIR" ]; then
    echo -e "${RED}Seleção inválida ou diretório de export não existe. Abortando importação.${NC}"
    exit 1
fi

echo -e "${GREEN}Export selecionado para importação: ${SELECTED_EXPORT_DIR}${NC}"

# 3. Criar diretório temporário dentro do volume para a importação
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
N8N_IMPORT_TEMP_DIR_IN_CONTAINER="${N8N_VOLUME_PATH_IN_CONTAINER}/temp_cli_import_${TIMESTAMP}"
HOST_TEMP_IMPORT_DIR="${HOST_N8N_VOLUME_ROOT_DIR}/temp_cli_import_${TIMESTAMP}"

echo -e "${YELLOW}Criando diretório temporário dentro do contêiner (e no host em: ${HOST_TEMP_IMPORT_DIR})...${NC}"
docker exec "$N8N_SERVICE_NAME" mkdir -p "$N8N_IMPORT_TEMP_DIR_IN_CONTAINER"
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao criar diretório temporário no contêiner. Abortando.${NC}"
    exit 1
fi

# 4. Copiar os arquivos de exportação para o diretório temporário no volume (acessível pelo contêiner)
echo -e "${YELLOW}Copiando arquivos de exportação de '${SELECTED_EXPORT_DIR}/' para '${HOST_TEMP_IMPORT_DIR}/' no host...${NC}"
rsync -a "${SELECTED_EXPORT_DIR}/" "${HOST_TEMP_IMPORT_DIR}/"
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao copiar arquivos para o diretório temporário do volume. Abortando.${NC}"
    docker exec "$N8N_SERVICE_NAME" rm -rf "$N8N_IMPORT_TEMP_DIR_IN_CONTAINER"
    exit 1
fi

# 5. Importar Credenciais (AGORA SEM A FLAG --force)
CREDENTIALS_FILE_IN_CONTAINER="${N8N_IMPORT_TEMP_DIR_IN_CONTAINER}/credentials.json"
HOST_CREDENTIALS_FILE="${HOST_TEMP_IMPORT_DIR}/credentials.json"

if [ -f "$HOST_CREDENTIALS_FILE" ]; then
    echo -e "${YELLOW}Importando credenciais de ${CREDENTIALS_FILE_IN_CONTAINER}...${NC}"
    # Removida a flag --force
    docker exec "$N8N_SERVICE_NAME" n8n import:credentials --input "$CREDENTIALS_FILE_IN_CONTAINER"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erro ao importar credenciais. Verifique os logs do contêiner. Credenciais existentes podem precisar ser removidas manualmente.${NC}"
    else
        echo -e "${GREEN}Credenciais importadas com sucesso.${NC}"
    fi
else
    echo -e "${YELLOW}Aviso: Arquivo de credenciais (${HOST_CREDENTIALS_FILE}) não encontrado no export selecionado. Pulando importação de credenciais.${NC}"
fi

# 6. Importar Workflows (AGORA SEM AS FLAGS --force e --activate)
WORKFLOWS_FILE_IN_CONTAINER="${N8N_IMPORT_TEMP_DIR_IN_CONTAINER}/workflows.json"
HOST_WORKFLOWS_FILE="${HOST_TEMP_IMPORT_DIR}/workflows.json"

if [ -f "$HOST_WORKFLOWS_FILE" ]; then
    echo -e "${YELLOW}Importando workflows de ${WORKFLOWS_FILE_IN_CONTAINER}...${NC}"
    # Removidas as flags --force e --activate
    docker exec "$N8N_SERVICE_NAME" n8n import:workflow --input "$WORKFLOWS_FILE_IN_CONTAINER"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erro ao importar workflows. Verifique os logs do contêiner. Workflows existentes podem precisar ser removidos manualmente e os novos ativados via UI.${NC}"
    else
        echo -e "${GREEN}Workflows importados com sucesso. (Lembre-se de ativá-los manualmente na UI do n8n).${NC}"
    fi
else
    echo -e "${YELLOW}Aviso: Arquivo de workflows (${HOST_WORKFLOWS_FILE}) não encontrado no export selecionado. Pulando importação de workflows.${NC}"
fi

# 7. Remover o diretório temporário do volume (dentro do contêiner)
echo -e "${YELLOW}Removendo diretório temporário de importação do contêiner...${NC}"
docker exec "$N8N_SERVICE_NAME" rm -rf "$N8N_IMPORT_TEMP_DIR_IN_CONTAINER"
if [ $? -ne 0 ]; then
    echo -e "${RED}Aviso: Erro ao remover diretório temporário no contêiner. Remova manualmente se necessário.${NC}"
fi

echo -e "${GREEN}Processo de importação via CLI concluído!${NC}"
echo -e "${GREEN}Acesse seu n8n para verificar os workflows e credenciais.${NC}"