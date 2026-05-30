# Project Handoff: Hermes Ultimate Dev Environment

**To:** Claude
**From:** Jarvis (Hermes Agent)
**Date:** 30 de maio de 2026

### 1. Resumo Executivo

O objetivo deste projeto foi criar um ambiente de desenvolvimento Docker "definitivo", portátil, persistente e "baterias-incluídas" para o usuário. O princípio central é uma **imagem stateless** contendo um vasto conjunto de ferramentas, com todo o estado do usuário (credenciais, código, configurações, sessões) mantido em **volumes stateful** no host, orquestrado pelo Docker Compose.

O projeto evoluiu iterativamente, começando com uma base Oracle Linux, passando por Ubuntu 22.04 e finalmente se estabelecendo na imagem `ubuntu:24.04`. O escopo das ferramentas foi significativamente expandido a pedido do usuário para cobrir desenvolvimento geral, IA, multi-cloud, DevOps e utilitários.

### 2. Estado Atual do Projeto

O projeto consiste nos seguintes arquivos, que juntos definem e documentam todo o ambiente:

-   `Dockerfile`: Define a imagem Docker com base no Ubuntu 24.04 e instala todas as ferramentas.
-   `docker-compose.yml`: Orquestra a construção da imagem e o gerenciamento dos volumes persistentes (`user_data` e `agent_data`).
-   `README.md`: Documentação completa do projeto, incluindo o inventário de ferramentas e um guia detalhado sobre como configurar credenciais.
-   `welcome.sh`: Um script de "Mensagem do Dia" que é executado no login do shell e exibe as versões de todas as ferramentas instaladas.
-   `.env.example`: Um arquivo de modelo para o usuário criar seu arquivo `.env` para gerenciar chaves de API e segredos.

### 3. Principais Decisões de Design e Evolução

-   **Imagem Stateless, Volumes Stateful**: A decisão arquitetônica mais crítica. A imagem é um "molde" descartável. Os diretórios `user_data` e `agent_data` no host contêm todos os dados persistentes, tornando as atualizações da imagem triviais e seguras.
-   **Gerenciamento de Credenciais**: Adotamos uma abordagem dupla:
    1.  **Arquivo `.env`**: Para chaves de API e tokens, carregados como variáveis de ambiente pelo Docker Compose.
    2.  **Login Interativo Persistente**: Para CLIs de nuvem e DevOps (`gcloud`, `aws`, `gh`), o usuário faz login uma vez de dentro do container, e a sessão é salva nos volumes persistentes.
-   **Experiência do Desenvolvedor**: O `README.md` detalhado e o script `welcome.sh` foram adicionados para tornar o ambiente fácil de entender, configurar e usar.
-   **Seleção de Ferramentas**: A lista de ferramentas foi curada pelo usuário para criar um ambiente de propósito geral extremamente versátil.

### 4. Inventário Completo de Ferramentas

-   **Core**: Hermes Agent, Playwright (com stealth)
-   **Linguagens**: Python 3.11, Node.js (última LTS via nvm), Go (1.22+), Java (Amazon Corretto 21)
-   **Build Tools**: Maven
-   **CLIs de IA**: Claude, Codex, Gemini
-   **CLIs de Cloud**: Google Cloud (`gcloud`), AWS (`aws`), Oracle Cloud (`oci`)
-   **CLIs de DevOps**: GitHub (`gh`), Atlassian (`atlassian`)
-   **Utilitários**: HTTPie (`http`), GOG Client (`gogcli`), PM2

### 5. Ponto de Continuidade e Próximo Passo Imediato

O usuário aprovou o estado atual do ambiente e agora deseja elevá-lo a um padrão de projeto de código aberto, automatizando seu ciclo de vida.

**A próxima tarefa é:**
**Mover o projeto para o GitHub e automatizar a construção e publicação da imagem Docker usando GitHub Actions.**

O plano sugerido é:
1.  O usuário criará um novo repositório no GitHub.
2.  Todos os arquivos do projeto (`Dockerfile`, `docker-compose.yml`, etc.) serão enviados para o repositório.
3.  Criar um workflow de GitHub Actions (em `.github/workflows/build-and-push.yml`).
4.  Este workflow deve ser acionado em `push` para a branch `main` ou na criação de uma `release`/`tag`.
5.  O workflow irá:
    a. Fazer o checkout do código.
    b. Fazer o login no GitHub Container Registry (GHCR).
    c. Construir a imagem Docker a partir do `Dockerfile`.
    d. Publicar (push) a imagem construída no GHCR, usando tags como `latest` e o número da versão do release.

### 6. Conteúdo dos Arquivos Finais (Para Referência)

<details>
<summary><code>Dockerfile</code></summary>

```dockerfile
# Usar a imagem base Ubuntu 24.04 LTS (Noble Numbat)
FROM ubuntu:24.04

# Metadados da imagem
LABEL maintainer="hermes-agent"
LABEL description="Ultimate development environment for Hermes Agent with Go, latest LTS Node, and a comprehensive set of CLIs (Ubuntu 24.04-based)."

# Variáveis de ambiente
ENV HERMES_USER=hermes
ENV HOME=/home/${HERMES_USER}
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto
ENV NVM_DIR=/home/hermes/.nvm
ENV GOROOT=/usr/local/go
ENV GOPATH=/home/hermes/go
ENV PATH="${GOROOT}/bin:${GOPATH}/bin:/usr/local/bin:/usr/lib/google-cloud-sdk/bin:${JAVA_HOME}/bin:${NVM_DIR}/versions/node/v20.14.0/bin:${HOME}/.local/bin:${HOME}/bin:${PATH}"

# Instalar dependências, Go, Python, Java e CLIs
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    curl \
    wget \
    gpg-agent \
    gnupg \
    git \
    openssh-client \
    sudo \
    tar \
    gzip \
    unzip \
    which \
    httpie && \
    # Instalar Go
    wget https://go.dev/dl/go1.22.3.linux-arm64.tar.gz -P /tmp && \
    tar -C /usr/local -xzf /tmp/go1.22.3.linux-arm64.tar.gz && \
    rm /tmp/go1.22.3.linux-arm64.tar.gz && \
    # Adicionar repositórios de terceiros
    wget -O- https://apt.corretto.aws/corretto.key | gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | tee /etc/apt/sources.list.d/corretto.list && \
    wget -O- https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list && \
    wget -O- https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list && \
    apt-get update -y && \
    # Instalar pacotes dos repositórios
    apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip \
    java-21-amazon-corretto-jdk \
    google-cloud-sdk \
    gh && \
    # Instalar CLIs via script (Atlassian, AWS)
    curl -sL https://packages.atlassian.com/install/cli/latest.sh | bash && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip ./aws && \
    # Limpeza
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Criar usuário não-root
RUN useradd -m -s /bin/bash ${HERMES_USER} && \
    echo "${HERMES_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Mudar para o usuário hermes
USER ${HERMES_USER}
WORKDIR ${HOME}

# Configurar o ambiente do usuário (Go, nvm)
RUN mkdir -p ${GOPATH}/{src,bin,pkg} && \
    echo 'export GOROOT=/usr/local/go' >> ${HOME}/.bashrc && \
    echo 'export GOPATH=${HOME}/go' >> ${HOME}/.bashrc && \
    echo 'export PATH=${GOROOT}/bin:${GOPATH}/bin:${PATH}' >> ${HOME}/.bashrc && \
    echo 'export NVM_DIR="$HOME/.nvm"' >> ${HOME}/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use' >> ${HOME}/.bashrc

# Instalar CLIs via script para o usuário (Oracle, gog)
RUN bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh) --accept-all-defaults" && \
    curl -sL https://gogcli.sh/install | sh

# Instalar Hermes Agent e CLIs de IA Python
RUN python3.11 -m pip install --upgrade pip && \
    python3.11 -m pip install hermes-agent playwright-stealth claude-cli claude-code openai-codex gemini-cli

# Instalar nvm e a última versão LTS do Node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && \
    . "${NVM_DIR}/nvm.sh" && \
    nvm install --lts && \
    nvm use --lts && \
    nvm alias default 'lts/*' && \
    npm install -g pm2

# Instalar Maven
RUN wget https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz -P /tmp && \
    sudo tar xf /tmp/apache-maven-3.9.6-bin.tar.gz -C /opt && \
    sudo ln -s /opt/apache-maven-3.9.6 /opt/maven && \
    rm /tmp/apache-maven-3.9.6-bin.tar.gz
ENV M2_HOME=/opt/maven
ENV PATH=${M2_HOME}/bin:${PATH}

# Instalar navegadores para Playwright
RUN playwright install --with-deps

# Configurar o diretório de trabalho padrão do Hermes
RUN mkdir -p ${HOME}/.hermes/

# Adicionar e configurar o script de boas-vindas
COPY welcome.sh /etc/welcome.sh
RUN chmod +x /etc/welcome.sh && \
    echo '' >> ${HOME}/.bashrc && \
    echo '# Execute o script de boas-vindas' >> ${HOME}/.bashrc && \
    echo '/etc/welcome.sh' >> ${HOME}/.bashrc

# Comando padrão
CMD ["tail", "-f", "/dev/null"]
```
</details>

<details>
<summary><code>docker-compose.yml</code></summary>

```yaml
services:
  hermes:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: hermes_dev_env
    # Carrega as variáveis do arquivo .env no container
    env_file:
      - .env
    volumes:
      # Mapeia o diretório de dados do agente para persistência
      - ./agent_data:/home/hermes/.hermes
      # Mapeia o diretório de dados do usuário
      - ./user_data/.ssh:/home/hermes/.ssh
      - ./user_data/.gitconfig:/home/hermes/.gitconfig
      - ./user_data/browser_session:/home/hermes/browser_session
      - ./user_data/workspaces:/home/hermes/workspaces
    # Mantém o container rodando em segundo plano
    stdin_open: true
    tty: true
```
</details>
