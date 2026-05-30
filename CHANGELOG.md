# Changelog

Todas as mudanças relevantes deste projeto são documentadas aqui.
O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/)
e o projeto adota [SemVer](https://semver.org/lang/pt-BR/).

## [Não lançado]

### Adicionado
- Estrutura de repositório para manutenção via GitHub.
- `.gitignore` cobrindo segredos (`.env`), chaves SSH, sessões de navegador e configs de nuvem.
- Documentação em `docs/`: `INSTALL`, `TOOLS`, `VERSIONS`, `CREDENTIALS`, `SECURITY`.
- `CHANGELOG.md`.
- **Pipeline CI/CD (GitHub-only):**
  - `ci.yml` — lint (hadolint/shellcheck), secret-scan (gitleaks), build, smoke test
    (`scripts/smoke-test.sh`) e Trivy informativo (SARIF → aba Security).
  - `release.yml` — tags `vX.Y.Z` (estável) e `bX.Y.Z` (beta): build multi-arch,
    **gate de Trivy (falha em CVE CRITICAL)**, push no GHCR e GitHub Release
    (beta = pre-release).
  - Substitui o antigo `build-and-push.yml`.
  - **Publicação também no Docker Hub** (além do GHCR), condicional à variável de repo
    `DOCKERHUB_REPO` (+ secrets `DOCKERHUB_USERNAME`/`DOCKERHUB_TOKEN`). Permite
    `docker pull` em qualquer lugar.
- `scripts/smoke-test.sh` reutilizável (CI + local).
- Templates de issue do GitHub (`.github/ISSUE_TEMPLATE/`: feature/bug) e `docs/CICD.md`.
- Bloco de `ARG` no topo do `Dockerfile` como fonte única de verdade das versões.
- Verificação de checksum (sha256) no download do gogcli.
- **`.dockerignore`** (segurança + tamanho): exclui `user_data/`, `.env`, `.git`, `docs/` do
  contexto de build.
- **`docs/SECURITY.md`** completo: modelo de ameaça, fluxo de credenciais (modelo
  _local por usuário_), riscos residuais, hardening opcional e checklist pré-commit.
- **Persistência dos logins de nuvem**: `docker-compose.yml` agora monta `~/.config`, `~/.aws`
  e `~/.oci` em `user_data/` (gcloud/gh/gemini/aws/oci sobrevivem à recriação do container).
- `env_file` marcado como `required: false` (não falha se o `.env` ainda não existe).
- Opção de hardening `no-new-privileges` documentada (comentada) no compose.

### Tamanho da imagem (redução conservadora)
- Playwright instala **apenas Chromium** (`playwright install chromium`) em vez de todos os
  navegadores.
- Limpeza de cache: `npm cache clean --force` e `PIP_NO_CACHE_DIR=1` para pip/pipx.

### Alterado
- **CLIs de IA agora via npm (método oficial):** `@anthropic-ai/claude-code@2.1.158`,
  `@google/gemini-cli@0.44.1`, `@openai/codex@0.135.0` (antes: `pip`, que estava incorreto).
- **Versões fixadas** para componentes antes flutuantes: Node.js `24.16.0`, gcloud `570.0.0`,
  AWS CLI `2.34.57`, gh `2.93.0`, oci-cli `3.84.0`, gogcli `0.19.0`, pm2 `7.0.1`,
  hermes-agent `0.15.2`, playwright `1.60.0`, playwright-stealth `2.0.3`.
- **Aplicações Python via `pipx`** (isoladas, compatível com PEP 668 do Noble): hermes-agent
  (com playwright/stealth injetados) e oci-cli.
- `welcome.sh` corrigido para os comandos reais: `claude`, `gemini`, `codex`, `acli`, `gog`.

### Corrigido
- **Arquitetura:** downloads selecionam amd64/arm64 via `TARGETARCH` (antes baixava binários
  ARM64 fixos, quebrando em x86_64).
- **Python:** uso do `python3` 3.12 do Noble (antes pedia `python3.11`, inexistente no repo);
  `welcome.sh` ajustado para `python3`.
- **PATH do Node.js** derivado da versão fixada (antes apontava para `v20.14.0` inexistente).
- **gogcli:** download usa o nome real do artefato para o `sha256sum -c` encontrá-lo
  (antes baixava como `gogcli.tgz` e a verificação falhava).
- **Posse do home do `hermes`:** `chown -R` após `useradd` corrige diretório poluído por
  etapas root anteriores (`gcloud install.sh` com `HOME=/home/hermes`).
- **Playwright via pipx:** `inject` da lib `playwright-stealth` sem `--include-apps`
  (a flag exigia que a lib tivesse CLIs próprios, o que não é o caso).

### Validação
- Build real concluído em `linux/amd64` (Docker Desktop 29.3.1). Imagem ~9.5 GB.
- Smoke test: todas as versões conferem; `hermes --help` ok; Playwright abre o Chromium
  headless e renderiza; `playwright-stealth` importa no venv.

### Pendente (ver docs/VERSIONS.md)
- Atlassian `acli`: sem URL versionada pública → permanece no canal `latest` (resolveu p/ 1.3.18-stable).
- Alinhamento dos volumes de persistência das CLIs de nuvem (gcloud/aws/gh/oci).
- Tamanho da imagem (~9.5 GB) — opções de redução documentadas.
