#!/bin/bash
# Script para exibir as versões das ferramentas instaladas ao iniciar o shell.

# Função para imprimir um separador
print_separator() {
    printf -- '-%.0s' {1..70}
    printf '\n'
}

# Função para imprimir um cabeçalho de seção
print_header() {
    echo
    echo "--- $1 ---"
}

# Ativa o NVM para garantir que os comandos do Node.js funcionem
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" --no-use &>/dev/null

clear
echo
print_separator
echo "     Welcome to the Ultimate Hermes Development Environment"
print_separator

# --- Linguagens e Runtimes ---
print_header "Languages & Runtimes"
echo -n "Python:    "; python3 --version 2>&1
echo -n "Node.js:   "; node --version 2>&1
echo -n "Java:      "; java --version 2>&1 | head -n 1
echo -n "Go:        "; go version 2>&1
echo -n "Maven:     "; mvn --version 2>&1 | head -n 1

# --- Core e IA ---
print_header "Core & AI Tools"
echo -n "Hermes:    "; (pipx list --short 2>/dev/null | awk '/hermes-agent/{print $2}') || echo "?"
echo -n "Playwright:"; playwright --version 2>&1
echo -n "Claude:    "; claude --version 2>&1 | head -n 1
echo -n "Codex:     "; codex --version 2>&1 | head -n 1
echo -n "Gemini:    "; gemini --version 2>&1 | head -n 1


# --- Cloud & DevOps CLIs ---
print_header "Cloud & DevOps CLIs"
echo -n "gcloud:    "; gcloud --version 2>&1 | head -n 1
echo -n "AWS:       "; aws --version 2>&1
echo -n "OCI:       "; oci --version 2>&1
echo -n "GitHub:    "; gh --version 2>&1 | head -n 1
echo -n "Atlassian: "; acli --version 2>&1 | head -n 1
echo -n "GOG:       "; gog --version 2>&1 | head -n 1

# --- Utilitários ---
print_header "Utilities"
echo -n "HTTPie:    "; http --version 2>&1
echo -n "PM2:       "; pm2 --version 2>&1

echo
print_separator
echo "  Your workspace is at: /home/hermes/workspaces/"
echo "  All configurations and sessions are persistent."
print_separator
echo
