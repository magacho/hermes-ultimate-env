#!/usr/bin/env bash
# Coleta versões e bibliotecas instaladas e grava um JSON (snapshot do build),
# consumido pelo app/info_server.py. Roda durante o build da imagem.
#   IMAGE_VERSION=<versão> collect-info.sh [caminho_saida]
set -euo pipefail
OUT="${1:-/opt/hermes/info/versions.json}"
mkdir -p "$(dirname "$OUT")"

IMAGE_VERSION="${IMAGE_VERSION:-dev}" python3 - "$OUT" <<'PY'
import json, os, subprocess, sys, datetime

out = sys.argv[1]

def run(cmd):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=90)
        return (r.stdout or r.stderr).strip()
    except Exception as e:
        return f"(erro: {e})"

def first(cmd):
    s = run(cmd)
    return s.splitlines()[0] if s else ""

data = {
    "image_version": os.environ.get("IMAGE_VERSION", "dev"),
    "build_date": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "runtimes": {
        "python": first("python3 --version"),
        "node": first("node --version"),
        "go": first("go version"),
        "java": first("java --version"),
        "maven": first("mvn --version"),
    },
    "ai_clis": {
        "claude": first("claude --version"),
        "gemini": first("gemini --version"),
        "codex": first("codex --version"),
        "hermes-agent": run("pipx list --short 2>/dev/null | awk '/hermes-agent/{print $2}'"),
        "playwright": first("playwright --version"),
    },
    "cloud_clis": {
        "gcloud": first("gcloud --version"),
        "aws": first("aws --version"),
        "oci": first("oci --version"),
        "gh": first("gh --version"),
        "acli": first("acli --version"),
        "gog": first("gog --version"),
    },
    "google_tools": {
        "himalaya": first("himalaya --version"),
        "gcalcli": first("gcalcli --version"),
        "gdrive": first("gdrive version"),
    },
    "libraries": {
        "pip_hermes": run("pipx runpip hermes-agent list --format=freeze 2>/dev/null"),
        "npm_global": run("npm ls -g --depth=0 2>/dev/null"),
    },
}
with open(out, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
print(f"versions.json escrito em {out} (release={data['image_version']})")
PY
