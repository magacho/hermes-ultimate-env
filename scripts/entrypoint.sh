#!/usr/bin/env bash
# Entrypoint: sobe o servidor de health/info em background e segue com o comando
# pedido (default: mantém o container vivo). Não derruba o container se o server cair.
set -e

: "${HERMES_INFO_PORT:=8080}"
: "${HERMES_INFO_BIND:=0.0.0.0}"

# Sobe o servidor de info/health em background.
nohup python3 /opt/hermes/app/info_server.py >/tmp/hermes-info.log 2>&1 &

exec "$@"
