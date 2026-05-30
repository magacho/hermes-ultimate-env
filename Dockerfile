# syntax=docker/dockerfile:1
# Usar a imagem base Ubuntu 24.04 LTS (Noble Numbat)
FROM ubuntu:24.04

# Arquitetura de destino, injetada automaticamente pelo buildx (amd64 | arm64).
ARG TARGETARCH

# ============================================================================
#  Versões fixadas — FONTE ÚNICA DE VERDADE (espelhada em docs/VERSIONS.md)
#  Para atualizar uma ferramenta, altere aqui e atualize VERSIONS.md + CHANGELOG.
# ============================================================================
# Linguagens / runtimes (versões já declaradas no projeto original)
ARG GO_VERSION=1.26.3
ARG NODE_VERSION=24.16.0
ARG NVM_VERSION=0.39.7
ARG MAVEN_VERSION=3.9.6
# CLIs de Cloud / DevOps
ARG GCLOUD_VERSION=570.0.0
ARG AWSCLI_VERSION=2.34.57
ARG GH_VERSION=2.93.0
ARG GOGCLI_VERSION=0.19.0
ARG OCI_CLI_VERSION=3.84.0
# CLIs de IA — instaladas via npm (método oficial de cada uma)
ARG CLAUDE_CODE_VERSION=2.1.158
ARG GEMINI_CLI_VERSION=0.44.1
ARG CODEX_VERSION=0.135.0
# Pacotes Python (instalados de forma isolada via pipx)
ARG HERMES_AGENT_VERSION=0.15.2
ARG PLAYWRIGHT_VERSION=1.60.0
ARG PLAYWRIGHT_STEALTH_VERSION=2.0.3
# Utilitários npm
ARG PM2_VERSION=7.0.1

# Metadados da imagem
LABEL maintainer="hermes-agent"
LABEL description="Ultimate development environment for Hermes Agent (Ubuntu 24.04, multi-arch, versões fixadas)."

# Variáveis de ambiente
ENV HERMES_USER=hermes
ENV HOME=/home/${HERMES_USER}
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto
ENV NVM_DIR=/home/hermes/.nvm
ENV GOROOT=/usr/local/go
ENV GOPATH=/home/hermes/go
ENV M2_HOME=/opt/maven
# O caminho do Node é derivado da versão fixada (NODE_VERSION), garantindo que
# `node`/`npm` estejam no PATH inclusive em shells não-interativos.
ENV PATH="${GOROOT}/bin:${GOPATH}/bin:${M2_HOME}/bin:/opt/google-cloud-sdk/bin:${JAVA_HOME}/bin:${NVM_DIR}/versions/node/v${NODE_VERSION}/bin:${HOME}/.local/bin:${HOME}/bin:/usr/local/bin:${PATH}"

# ----------------------------------------------------------------------------
# 1) Pacotes base do APT + repositório Amazon Corretto (Java 21) + Python 3.12
# ----------------------------------------------------------------------------
RUN set -eux; \
    apt-get update -y; \
    apt-get install -y --no-install-recommends \
      apt-transport-https ca-certificates software-properties-common \
      curl wget gpg-agent gnupg git openssh-client sudo \
      tar gzip unzip xz-utils which build-essential \
      httpie \
      python3 python3-venv python3-dev pipx; \
    # Repositório Amazon Corretto
    wget -qO- https://apt.corretto.aws/corretto.key | gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg; \
    echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" > /etc/apt/sources.list.d/corretto.list; \
    apt-get update -y; \
    apt-get install -y --no-install-recommends java-21-amazon-corretto-jdk; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# 2) Ferramentas de sistema com versões fixadas e seleção por arquitetura
#    (Go, Maven, Google Cloud SDK, AWS CLI, GitHub CLI, gogcli, Atlassian acli)
# ----------------------------------------------------------------------------
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) GOARCH=amd64; AWSARCH=x86_64; GCARCH=x86_64; DEBARCH=amd64 ;; \
      arm64) GOARCH=arm64; AWSARCH=aarch64; GCARCH=arm;    DEBARCH=arm64 ;; \
      *) echo "Arquitetura não suportada: '${TARGETARCH}'"; exit 1 ;; \
    esac; \
    \
    # --- Go (tarball oficial) ---
    curl -fsSL -o /tmp/go.tgz "https://go.dev/dl/go${GO_VERSION}.linux-${GOARCH}.tar.gz"; \
    tar -C /usr/local -xzf /tmp/go.tgz; \
    \
    # --- Maven (archive.apache.org mantém todas as versões → reprodutível) ---
    curl -fsSL -o /tmp/maven.tgz "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"; \
    tar -C /opt -xzf /tmp/maven.tgz; \
    ln -s "/opt/apache-maven-${MAVEN_VERSION}" /opt/maven; \
    \
    # --- Google Cloud SDK (tarball versionado) ---
    curl -fsSL -o /tmp/gcloud.tgz "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-linux-${GCARCH}.tar.gz"; \
    tar -C /opt -xzf /tmp/gcloud.tgz; \
    /opt/google-cloud-sdk/install.sh --quiet --usage-reporting=false --path-update=false --command-completion=false; \
    \
    # --- AWS CLI v2 (instalador versionado) ---
    curl -fsSL -o /tmp/awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-${AWSARCH}-${AWSCLI_VERSION}.zip"; \
    unzip -q /tmp/awscliv2.zip -d /tmp; \
    /tmp/aws/install; \
    \
    # --- GitHub CLI (.deb versionado) ---
    curl -fsSL -o /tmp/gh.deb "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${DEBARCH}.deb"; \
    dpkg -i /tmp/gh.deb; \
    \
    # --- gogcli (release GitHub + verificação de checksum) ---
    # Baixa com o nome real do artefato para que o `sha256sum -c` encontre o arquivo.
    GOGFILE="gogcli_${GOGCLI_VERSION}_linux_${GOARCH}.tar.gz"; \
    curl -fsSL -o "/tmp/${GOGFILE}" "https://github.com/openclaw/gogcli/releases/download/v${GOGCLI_VERSION}/${GOGFILE}"; \
    curl -fsSL -o /tmp/checksums.txt "https://github.com/openclaw/gogcli/releases/download/v${GOGCLI_VERSION}/checksums.txt"; \
    (cd /tmp && grep "${GOGFILE}" checksums.txt | sha256sum -c -); \
    mkdir -p /tmp/gogcli && tar -C /tmp/gogcli -xzf "/tmp/${GOGFILE}"; \
    install -m 0755 /tmp/gogcli/gog /usr/local/bin/gog; \
    \
    # --- Atlassian CLI (acli) ---
    # NÃO pinável: o bucket S3 só expõe o canal "latest" (ver docs/VERSIONS.md).
    curl -fsSL -o /usr/local/bin/acli "https://acli.atlassian.com/linux/latest/acli_linux_${DEBARCH}/acli"; \
    chmod +x /usr/local/bin/acli; \
    \
    # --- Limpeza ---
    rm -rf /tmp/*

# ----------------------------------------------------------------------------
# 3) Usuário não-root
# ----------------------------------------------------------------------------
RUN useradd -m -s /bin/bash ${HERMES_USER} && \
    mkdir -p ${HOME} && \
    # Etapas root anteriores (ex.: gcloud install.sh com HOME=/home/hermes) podem
    # ter criado arquivos sob posse do root no home; garante a posse do usuário.
    chown -R ${HERMES_USER}:${HERMES_USER} ${HOME} && \
    echo "${HERMES_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${HERMES_USER}
WORKDIR ${HOME}

# ----------------------------------------------------------------------------
# 4) Ambiente do usuário (Go, nvm) no .bashrc
# ----------------------------------------------------------------------------
RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin ${GOPATH}/pkg && \
    { \
      echo 'export GOROOT=/usr/local/go'; \
      echo 'export GOPATH=$HOME/go'; \
      echo 'export PATH=$GOROOT/bin:$GOPATH/bin:$PATH'; \
      echo 'export NVM_DIR="$HOME/.nvm"'; \
      echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use'; \
    } >> ${HOME}/.bashrc

# ----------------------------------------------------------------------------
# 5) Node.js (nvm, versão fixada) + CLIs de IA via npm (método oficial) + pm2
# ----------------------------------------------------------------------------
RUN curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash && \
    . "${NVM_DIR}/nvm.sh" && \
    nvm install "${NODE_VERSION}" && \
    nvm alias default "${NODE_VERSION}" && \
    nvm use default && \
    npm install -g \
      "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
      "@google/gemini-cli@${GEMINI_CLI_VERSION}" \
      "@openai/codex@${CODEX_VERSION}" \
      "pm2@${PM2_VERSION}" && \
    npm cache clean --force

# ----------------------------------------------------------------------------
# 6) Hermes Agent, Playwright e Oracle Cloud CLI — cada um em venv pipx isolado
#    pipx é o método recomendado para CLIs Python e respeita o PEP 668 do Noble.
#    hermes-agent[all,anthropic]: extra "all" do autor + suporte a Claude/Anthropic.
#    Playwright fica em venv próprio (hermes-agent não depende de Playwright).
# ----------------------------------------------------------------------------
# Evita que pip/pipx deixem cache na imagem (redução de tamanho)
ENV PIP_NO_CACHE_DIR=1
RUN pipx install "hermes-agent[all,anthropic]==${HERMES_AGENT_VERSION}" && \
    pipx install "playwright==${PLAYWRIGHT_VERSION}" && \
    pipx inject playwright "playwright-stealth==${PLAYWRIGHT_STEALTH_VERSION}" && \
    pipx install "oci-cli==${OCI_CLI_VERSION}"

# Navegadores do Playwright — apenas Chromium (reduz ~1 GB vs. instalar todos)
RUN playwright install --with-deps chromium

# ----------------------------------------------------------------------------
# 7) Configuração final
# ----------------------------------------------------------------------------
RUN mkdir -p ${HOME}/.hermes/

COPY welcome.sh /etc/welcome.sh
USER root
RUN chmod +x /etc/welcome.sh
USER ${HERMES_USER}
RUN { echo ''; echo '# Executa o script de boas-vindas'; echo '/etc/welcome.sh'; } >> ${HOME}/.bashrc

# Comando padrão
CMD ["tail", "-f", "/dev/null"]
