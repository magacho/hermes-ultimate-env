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
- **Servidor de health/info embutido** (`app/info_server.py`, stdlib, porta 8080):
  - `GET /health` (também é o `HEALTHCHECK` do Docker e o do compose),
  - `GET /` página HTML com release + versões + bibliotecas (`pip`/`npm`),
  - `GET /release.json` com o inventário em JSON.
  - Dados capturados no build por `scripts/collect-info.sh` (snapshot); versão da imagem
    via `--build-arg IMAGE_VERSION` (o `release.yml` passa a tag).
  - Sobe via `entrypoint.sh` em background; container segue acessível por `exec`.
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

### Ferramentas Google (conta pessoal)
- Adicionadas CLIs: **himalaya** 1.2.0 (Gmail), **gcalcli** 4.5.1 (Calendar, via pipx) e
  **gdrive** 3.9.1 (Drive — **só amd64**; upstream não publica binário arm64).
- Refletidas no `welcome.sh`, no servidor de info (`/` e `/release.json`) e nas docs.

### Integrações do hermes-agent (expandidas)
- Adicionados extras: **mensageria** (`messaging` = Telegram/Discord/Slack, + `matrix`, `wecom`,
  `dingtalk`, `feishu`), **busca/scraping** (`exa`, `firecrawl`, `parallel-web`) e **`honcho`**.
- `libolm-dev` adicionado à camada apt (necessário para `mautrix[encryption]`/`python-olm` do Matrix).
- Set final: `hermes-agent[all,anthropic,messaging,matrix,wecom,dingtalk,feishu,exa,firecrawl,parallel-web,honcho]`.
- Resolução validada em venv limpo antes do build (sem conflito; imports de olm/mautrix OK).

### CI/CD (performance de build)
- **Release reescrita em jobs nativos paralelos** (sem QEMU): `meta` → `build-amd64`
  (x86, com Trivy gate) ‖ `build-arm64` (runner `ubuntu-24.04-arm` nativo) → `merge`
  (manifesto multi-arch via `imagetools` + cosign + GitHub Release). Push **por digest** por
  arquitetura. Cache buildx com `scope` por plataforma. Meta: release ~45min → ~10–18min.
  Telemetria por etapa **descartada** (dado já existe no Actions). Ver `docs/BUILD_OPTIMIZATION.md`.

### Segurança (assinatura de imagem)
- **Assinatura keyless com cosign** (OIDC do GitHub Actions, `id-token: write`) em toda release,
  por digest, em **cada registry (GHCR e Docker Hub)** — sem chave armazenada. Incorpora a
  proposta do PR #6 (Copilot) corrigida para o pipeline multi-registry atual; docs de
  verificação em `CICD.md` e `SECURITY.md`. (issue #3)

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
- **Go 1.22.3 → 1.26.3:** o gate de Trivy barrou a release por 2 CVEs CRITICAL no stdlib do Go
  (CVE-2024-24790, CVE-2025-68121). Atualizado para a estável atual, que corrige ambos.
- **Ref do `trivy-action`:** `v0.36.0` (faltava o prefixo `v` — derrubava o job no setup).
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
