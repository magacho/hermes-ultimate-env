#!/usr/bin/env bash
# Smoke test do ambiente: confirma que as ferramentas-chave existem no PATH e
# que o Playwright realmente abre o Chromium. Usado pelo CI e localmente.
#   docker run --rm -v "$PWD/scripts:/scripts" --entrypoint bash <imagem> /scripts/smoke-test.sh
set -euo pipefail

echo "== Verificando binários no PATH =="
MISSING=0
for c in hermes claude gemini codex go node npm java mvn \
         gcloud aws oci gh acli gog http pm2 playwright python3; do
  if command -v "$c" >/dev/null 2>&1; then
    printf '  ok  %s\n' "$c"
  else
    printf '  !!  FALTANDO: %s\n' "$c"; MISSING=1
  fi
done
[ "$MISSING" -eq 0 ] || { echo "Smoke test falhou: binário(s) ausente(s)."; exit 1; }

echo "== Testando launch do Chromium via Playwright =="
~/.local/share/pipx/venvs/playwright/bin/python -c "
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b = p.chromium.launch(headless=True)
    pg = b.new_page(); pg.goto('data:text/html,<h1>ok</h1>')
    assert 'ok' in pg.content(), 'conteúdo inesperado'
    b.close()
print('  ok  chromium headless renderizou')
import playwright_stealth  # noqa: F401
print('  ok  playwright_stealth importável')
"

echo "SMOKE OK"
