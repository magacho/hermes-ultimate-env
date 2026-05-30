# CI/CD e Releases

Todo o ciclo de vida do projeto vive no **GitHub**: código no repositório, imagem no
**GitHub Container Registry (GHCR)**, issues e releases no GitHub. Não há dependências externas.

## Workflows

### `ci.yml` — Validação contínua
**Dispara em:** Pull Requests, push para `main`, e manualmente (`workflow_dispatch`).

| Job | O que faz |
|-----|-----------|
| **lint** | `hadolint` no `Dockerfile` (falha só em erros) + `shellcheck` nos scripts |
| **secret-scan** | `gitleaks` varre o repositório em busca de segredos vazados |
| **build-smoke** | Builda a imagem (amd64), roda `scripts/smoke-test.sh` (binários + Playwright abre o Chromium) e um scan **Trivy informativo** (SARIF → aba *Security*) |

### `release.yml` — Build, scan e publicação
**Dispara em:** tags `vX.Y.Z` (estável) e `bX.Y.Z` (beta), e manualmente.

Fluxo (jobs **nativos paralelos**, sem QEMU):
1. **`meta`** — resolve canal pela tag (`v`=estável, `b`=beta) e os nomes/sufixos de imagem.
2. **`build-amd64`** (runner x86 nativo) — **Trivy (SARIF + gate `CRITICAL`)** e, se passar,
   **push por digest** (GHCR + Docker Hub).
3. **`build-arm64`** (runner **ARM nativo `ubuntu-24.04-arm`**) — push por digest, **em paralelo**
   com o amd64.
4. **`merge`** — monta o **manifesto multi-arch** em cada registry (`imagetools create`),
   **assina com cosign (keyless via OIDC)** por digest do índice, e cria o **GitHub Release**
   (beta = *pre-release*).

> Builds por arquitetura em **runners nativos paralelos** eliminam a emulação QEMU do arm64 —
> o release saiu da faixa de ~45 min para ~10–18 min. Ver [BUILD_OPTIMIZATION.md](BUILD_OPTIMIZATION.md).

> Os builds recebem `--build-arg IMAGE_VERSION=<versão>`, que alimenta o servidor de
> health/info embutido (`GET /` e `/release.json`) — assim a página da release mostra a
> versão correta e o inventário de versões/bibliotecas daquela imagem.

## Registries de destino

A imagem é publicada em **dois** registries (use o que preferir — a imagem é a mesma):

- **GHCR** (`ghcr.io/<owner>/<repo>`): sempre, autenticado pelo `GITHUB_TOKEN` (sem config).
- **Docker Hub** (`docker.io/<DOCKERHUB_REPO>`): se a variável `DOCKERHUB_REPO` estiver
  configurada (ver [Configuração](#permissões--configuração)). Pensado para usar "em qualquer
  lugar" com um `docker pull` simples.

## Convenção de versões e tags

| Tag Git | Canal | Tags publicadas (em cada registry) | GitHub Release |
|---------|-------|------------------------------------|----------------|
| `vX.Y.Z` | estável | `X.Y.Z`, `X.Y`, `latest` | release normal |
| `bX.Y.Z` | beta | `X.Y.Z-beta`, `beta` | *pre-release* |

> Beta **nunca** recebe a tag `latest`, para não virar o default de quem faz `docker pull`.

### Como lançar

```bash
# Estável
git tag v1.0.0 && git push origin v1.0.0

# Beta
git tag b1.1.0 && git push origin b1.1.0
```

Ou pela aba **Actions → Release → Run workflow**, informando a tag.

## Segurança no pipeline

- **Scan de imagem:** Trivy em toda CI (informativo) e em toda release (com gate em `CRITICAL`).
  Resultados aparecem em **Security → Code scanning alerts** (formato SARIF).
- **Assinatura de imagem:** toda imagem de release é assinada com **cosign keyless** (OIDC do
  GitHub Actions, sem chave armazenada), por digest, em cada registry (GHCR e Docker Hub).
- **Segredos:** `gitleaks` em cada PR/push; `.gitignore` + `.dockerignore` impedem que segredos
  entrem no repo ou na imagem (ver [SECURITY.md](SECURITY.md)).
- **Lint:** `hadolint` sinaliza más práticas no `Dockerfile`.
- `ignore-unfixed: true` no Trivy evita bloquear por CVEs ainda sem correção upstream.

## Permissões / configuração

### GHCR — automático
Usa o `GITHUB_TOKEN` (sem segredos manuais):
- `packages: write` → push no GHCR · `security-events: write` → SARIF · `contents: write` → Release
- `id-token: write` → OIDC para assinatura keyless com cosign (sem chave armazenada)

Para tornar a imagem pública, ajuste a visibilidade do *package* nas configurações do GHCR.

### Docker Hub — configuração necessária (uma vez)
Em **Settings → Secrets and variables → Actions** do repositório:

| Tipo | Nome | Valor |
|------|------|-------|
| Variable | `DOCKERHUB_REPO` | repositório destino, ex.: `magacho/hermes-ultimate-env` |
| Secret | `DOCKERHUB_USERNAME` | seu usuário do Docker Hub |
| Secret | `DOCKERHUB_TOKEN` | *Access Token* do Docker Hub (Account Settings → Security) com permissão de escrita |

> Enquanto `DOCKERHUB_REPO` não estiver definida, o pipeline **pula** o Docker Hub e publica
> só no GHCR (sem falhar). Crie o repositório no Docker Hub antes da primeira release.

```bash
# Após configurar, qualquer máquina pode:
docker pull <DOCKERHUB_REPO>:latest      # ex.: docker pull magacho/hermes-ultimate-env:latest
```

## Verificação da assinatura (cosign)

As imagens de release são assinadas com **cosign keyless**. Para verificar (consumidor):

```bash
IMAGE=ghcr.io/<owner>/<repo>:latest      # ou docker.io/<DOCKERHUB_REPO>:latest

cosign verify "$IMAGE" \
  --certificate-identity-regexp "^https://github.com/<owner>/<repo>/.github/workflows/release.yml@refs/tags/.+$" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"
```

> Para beta, troque a tag por `:beta` (ou `:X.Y.Z-beta`). Para máxima imutabilidade, verifique
> por digest: `cosign verify "ghcr.io/<owner>/<repo>@sha256:<digest>" ...`.

## Processo de novas features

Toda nova feature/bug é rastreada por **GitHub Issues** (templates em
`.github/ISSUE_TEMPLATE/`). Fluxo sugerido: issue → branch → PR (dispara `ci.yml`) →
merge em `main` → quando acumular escopo, criar tag `vX.Y.Z`/`bX.Y.Z` para release.
