# Instalação e Uso

## Pré-requisitos

- **Docker Engine** 24+ com **Docker Compose v2** (`docker compose`, sem hífen).
- Para build **multi-arch** local: `docker buildx` (já incluso no Docker moderno) e,
  para emular outra arquitetura, `qemu-user-static`.
- ~10–15 GB livres de disco (a imagem é grande: multi-cloud SDKs + navegadores Playwright + JDK).

Verifique:

```bash
docker --version
docker compose version
docker buildx version
```

---

## Opção A — Build local com Docker Compose (recomendado para uso diário)

```bash
# 1. Chaves de API
cp .env.example .env && $EDITOR .env

# 2. Build + sobe em background
docker compose up --build -d

# 3. Acessa o shell do ambiente
docker compose exec hermes bash

# Health & info (servidor embutido na porta 8080)
curl localhost:8080/health        # status ao vivo
# http://localhost:8080/          # página com versões e bibliotecas

# Parar / remover (os volumes em user_data/ e agent_data/ permanecem no host)
docker compose down
```

> O `docker compose ps` mostra o status do healthcheck (`healthy`) graças ao `HEALTHCHECK`
> da imagem, que bate em `/health`.

A primeira credencial interativa de cada CLI de nuvem deve ser feita uma vez dentro
do container — veja [CREDENTIALS.md](CREDENTIALS.md).

---

## Opção B — Build manual com buildx (multi-arch)

```bash
# Cria um builder com suporte multi-plataforma (uma vez)
docker buildx create --name hermes --use --bootstrap

# Build para amd64 + arm64. Para multi-arch é preciso --push (registry)
# ou --load apenas para UMA plataforma local.
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/<owner>/hermes-ultimate-env:dev \
  --push .
```

> Build local de **uma** arquitetura só (carrega no Docker local):
> ```bash
> docker buildx build --platform linux/amd64 -t hermes-ultimate-env:local --load .
> ```

---

## Opção C — Pull da imagem publicada

A release publica nos dois registries (use o que preferir):

```bash
# Docker Hub (mais universal)
docker pull <DOCKERHUB_REPO>:latest        # ex.: magacho/hermes-ultimate-env:latest
docker pull <DOCKERHUB_REPO>:0.1.0

# GHCR
docker pull ghcr.io/<owner>/hermes-ultimate-env:latest
docker pull ghcr.io/<owner>/hermes-ultimate-env:0.1.0
```

Para usar a imagem publicada com o compose, troque o bloco `build:` por
`image: <DOCKERHUB_REPO>:latest` (ou a ref do GHCR) no `docker-compose.yml`.

---

## CI/CD — Publicação automática no GHCR

O pipeline (`.github/workflows/ci.yml` e `release.yml`) valida e publica via GitHub.
Visão geral aqui; detalhes completos em [CICD.md](CICD.md).

- **CI** (PRs/push para `main`): lint, secret-scan, build, smoke test e Trivy informativo.
- **Release** (tags `vX.Y.Z`/`bX.Y.Z`): build multi-arch `amd64`+`arm64`, **gate de Trivy
  (falha em CVE CRITICAL)**, push no GHCR e GitHub Release.
- Autentica com o `GITHUB_TOKEN` automático — nenhum segredo adicional necessário.

### Como lançar uma versão

```bash
git tag v1.0.0 && git push origin v1.0.0   # estável → tags X.Y.Z, X.Y, latest
git tag b1.1.0 && git push origin b1.1.0   # beta    → tags X.Y.Z-beta, beta (pre-release)
```
