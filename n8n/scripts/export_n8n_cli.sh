#!/bin/bash

# --- Configurações ---
N8N_SERVICE_NAME="n8n"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUPS_CLI_DIR="${PROJECT_ROOT}/backups_cli" # Diretório para exports CLI

HOST_N8N_VOLUME_ROOT_DIR="${PROJECT_ROOT}/n8n"
N8N_VOLUME_PATH_IN_CONTAINER="/home/node/.n8n"

# --- Cores para o terminal ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Iniciando processo de exportação de dados do n8n via CLI...${NC}"
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

# 2. Criar diretório de backup com timestamp no host
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CURRENT_EXPORT_DIR="${BACKUPS_CLI_DIR}/n8n_export_cli_${TIMESTAMP}"
echo -e "${YELLOW}Criando diretório de exportação no host: ${CURRENT_EXPORT_DIR}${NC}"
mkdir -p "$CURRENT_EXPORT_DIR"
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao criar diretório de exportação no host. Abortando.${NC}"
    exit 1
fi

# 3. Definir caminhos temporários no contêiner/host para a exportação
N8N_EXPORT_TEMP_DIR_IN_CONTAINER="${N8N_VOLUME_PATH_IN_CONTAINER}/temp_cli_export_${TIMESTAMP}"
WORKFLOWS_FILE_IN_CONTAINER="${N8N_EXPORT_TEMP_DIR_IN_CONTAINER}/workflows.json" # Um único arquivo JSON para todos os workflows
N8N_CREDENTIALS_FILE_IN_CONTAINER="${N8N_EXPORT_TEMP_DIR_IN_CONTAINER}/credentials.json"
HOST_TEMP_EXPORT_DIR="${HOST_N8N_VOLUME_ROOT_DIR}/temp_cli_export_${TIMESTAMP}" # Caminho completo da pasta temporária no HOST

# 4. Criar o diretório temporário dentro do volume (isso o cria no host também)
echo -e "${YELLOW}Criando diretório temporário dentro do contêiner (e no host em: ${HOST_TEMP_EXPORT_DIR})...${NC}"
docker exec "$N8N_SERVICE_NAME" mkdir -p "$N8N_EXPORT_TEMP_DIR_IN_CONTAINER"
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao criar diretório temporário no contêiner. Abortando.${NC}"
    exit 1
fi

# 5. Exportar Workflows (para um único arquivo JSON)
echo -e "${YELLOW}Exportando todos os workflows para ${WORKFLOWS_FILE_IN_CONTAINER}...${NC}"
docker exec "$N8N_SERVICE_NAME" n8n export:workflow --all --output "$WORKFLOWS_FILE_IN_CONTAINER"
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao exportar workflows. Verifique os logs do contêiner. A mensagem do n8n foi: 'The parameter --output must be a writeable file'.${NC}"
else
    echo -e "${GREEN}Workflows exportados com sucesso para ${WORKFLOWS_FILE_IN_CONTAINER}.${NC}"
fi

# 6. Exportar Credenciais (DECRYPTED)
echo -e "${RED}ATENÇÃO: Exportando credenciais DECRYPTED! Certifique-se de que este é um ambiente seguro.${NC}"
echo -e "${YELLOW}Exportando todas as credenciais para ${N8N_CREDENTIALS_FILE_IN_CONTAINER}...${NC}"
docker exec "$N8N_SERVICE_NAME" n8n export:credentials --all --decrypted --output "$N8N_CREDENTIALS_FILE_IN_CONTAINER"
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao exportar credenciais. Verifique os logs do contêiner.${NC}"
else
    echo -e "${GREEN}Credenciais exportadas (descriptografadas) com sucesso.${NC}"
fi

# 7. Mover os arquivos exportados do volume temporário para o diretório de backup no host
echo -e "${YELLOW}Movendo arquivos exportados de '${HOST_TEMP_EXPORT_DIR}/' para '${CURRENT_EXPORT_DIR}/' no host...${NC}"
rsync -a "${HOST_TEMP_EXPORT_DIR}/" "${CURRENT_EXPORT_DIR}/"
if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao mover/copiar arquivos exportados para o diretório final no host.${NC}"
    echo -e "${RED}Verifique se o diretório temporário realmente existe e tem conteúdo: ${HOST_TEMP_EXPORT_DIR}${NC}"
else
    echo -e "${GREEN}Arquivos de exportação movidos para: ${CURRENT_EXPORT_DIR}${NC}"
fi

# 8. Remover o diretório temporário do volume (dentro do contêiner)
echo -e "${YELLOW}Removendo diretório temporário de exportação do contêiner...${NC}"
docker exec "$N8N_SERVICE_NAME" rm -rf "$N8N_EXPORT_TEMP_DIR_IN_CONTAINER"
if [ $? -ne 0 ]; then
    echo -e "${RED}Aviso: Erro ao remover diretório temporário no contêiner. Remova manualmente se necessário.${NC}"
fi

echo -e "${GREEN}Processo de exportação via CLI concluído!${NC}"
echo -e "${GREEN}Workflows e credenciais (descriptografadas) salvos em: ${CURRENT_EXPORT_DIR}${NC}"