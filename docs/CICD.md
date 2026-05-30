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

Fluxo:
1. Resolve o canal pela tag (`v` = estável, `b` = beta) e calcula as tags de imagem.
2. **Build amd64 local** como alvo do scan.
3. **Trivy (SARIF)** → relatório na aba *Security* (não bloqueia).
4. **Trivy (gate)** → **falha a release se houver CVE `CRITICAL`** (corrigível).
5. **Build multi-arch (amd64+arm64)** e **push no GHCR** — só após passar no gate.
6. **Assinatura da imagem com cosign (keyless via OIDC do GitHub)**.
7. **GitHub Release** (beta marcado como *pre-release*, com notas geradas).

## Convenção de versões e tags

| Tag Git | Canal | Tags publicadas no GHCR | GitHub Release |
|---------|-------|-------------------------|----------------|
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
- **Assinatura de imagem:** toda imagem publicada no GHCR é assinada com **cosign keyless**
  usando o OIDC do GitHub Actions.
- **Segredos:** `gitleaks` em cada PR/push; `.gitignore` + `.dockerignore` impedem que segredos
  entrem no repo ou na imagem (ver [SECURITY.md](SECURITY.md)).
- **Lint:** `hadolint` sinaliza más práticas no `Dockerfile`.
- `ignore-unfixed: true` no Trivy evita bloquear por CVEs ainda sem correção upstream.

## Permissões / configuração

Nenhum segredo manual é necessário — o pipeline usa o `GITHUB_TOKEN` automático:
- `packages: write` → push no GHCR
- `security-events: write` → upload do SARIF
- `contents: write` → criar o GitHub Release
- `id-token: write` → emitir token OIDC para assinatura keyless com cosign

A imagem publicada fica em `ghcr.io/<owner>/<repo>`. Para torná-la pública, ajuste a
visibilidade do *package* nas configurações do GHCR.

## Verificação da assinatura da imagem (cosign)

Após uma release, valide a assinatura keyless da imagem no GHCR:

```bash
IMAGE=ghcr.io/<owner>/<repo>:latest
OWNER=<owner>
REPO=<repo>

cosign verify "$IMAGE" \
  --certificate-identity-regexp "^https://github.com/${OWNER}/${REPO}/.github/workflows/release.yml@refs/tags/.+$" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"
```

> Para beta, troque a tag por `:beta`; para versões fixas, use `:X.Y.Z`/`:X.Y.Z-beta`.

## Processo de novas features

Toda nova feature/bug é rastreada por **GitHub Issues** (templates em
`.github/ISSUE_TEMPLATE/`). Fluxo sugerido: issue → branch → PR (dispara `ci.yml`) →
merge em `main` → quando acumular escopo, criar tag `vX.Y.Z`/`bX.Y.Z` para release.
