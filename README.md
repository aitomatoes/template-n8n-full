# Stack de Automação com N8N, Supabase & Evolution API

Este repositório é um template para inicializar rapidamente uma stack completa de backend para automação, focada em fluxos de trabalho de IA. A stack integra **N8N**, **Supabase**, **Evolution API** e **Redis**, todos orquestrados com Docker Compose para um ambiente de desenvolvimento e produção simplificado.

O objetivo é fornecer uma base sólida e pré-configurada, permitindo que os desenvolvedores foquem na criação dos fluxos de automação em vez de se preocuparem com a infraestrutura.

## Arquitetura

A arquitetura deste projeto é baseada em microsserviços, onde cada componente principal (Supabase, N8N, etc.) opera em seu próprio contêiner Docker e é definido em seu próprio arquivo `docker-compose.yml`.

A comunicação entre todos esses serviços é possível através de uma **rede Docker compartilhada**, chamada `coral-home-net`, que é criada e gerenciada pelos scripts de inicialização. Isso garante que, por exemplo, o N8N possa se conectar ao banco de dados do Supabase ou utilizar o Redis como cache, de forma segura e eficiente.

## Tecnologias

| Tecnologia | Função |
| :--- | :--- |
| **Supabase** | Backend-as-a-Service: Banco de dados Postgres, autenticação, storage e APIs automáticas. |
| **N8N** | Plataforma de automação de fluxos de trabalho (low-code), o cérebro das nossas automações. |
| **Evolution API** | Gateway não-oficial para a API do WhatsApp, permitindo o envio e recebimento de mensagens. |
| **Redis** | Banco de dados em memória de alta performance, usado para cache e filas. |
| **Docker & Docker Compose**| Containerização e orquestração de toda a stack. |
| **Infisical** | Plataforma para gerenciamento centralizado de segredos e credenciais (recomendado). |

## Pré-requisitos

Antes de começar, garanta que você tenha as seguintes ferramentas instaladas em sua máquina:
* [Docker](https://www.docker.com/get-started)
* [Docker Compose](https://docs.docker.com/compose/install/) (geralmente já vem com o Docker Desktop)
* [Infisical CLI](https://infisical.com/docs/cli/overview) (Opcional, se for usar o método de gerenciamento de segredos recomendado)
* [Git](https://git-scm.com/downloads)

## Configuração

Siga os passos abaixo para configurar o ambiente localmente.

### 1. Clonar o Repositório

```bash
git clone <URL_DO_SEU_REPOSITORIO>
cd <NOME_DO_REPOSITORIO>