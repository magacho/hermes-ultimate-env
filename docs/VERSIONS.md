# Versões de Software

Todas as versões são **fixadas** via `ARG` no topo do [`Dockerfile`](../Dockerfile), que é a
**fonte única de verdade**. Esta tabela espelha esses valores. Para atualizar uma ferramenta:
altere o `ARG` no Dockerfile, atualize esta tabela e registre no [CHANGELOG](../CHANGELOG.md).

> Conferir as versões reais de uma imagem já construída:
> ```bash
> docker compose exec hermes bash /etc/welcome.sh
> ```

_Última revisão das versões: 2026-05-30._

> ✅ **Imagem validada por build real** em `linux/amd64` (Docker Desktop 29.3.1).
> Tamanho: **~7.3 GB** após redução conservadora (era ~9.5 GB; Chromium-only + limpeza de cache).
> Todas as ferramentas tiveram smoke test (versões conferem, `hermes --help` ok, Playwright
> abre o Chromium headless). Detalhes no [CHANGELOG](../CHANGELOG.md).

## Base

| Componente | Versão | Fonte |
|------------|--------|-------|
| Imagem base | `ubuntu:24.04` (Noble) | Docker Hub |
| Python | `3.12` (padrão do Noble) | `apt` |

## Linguagens e Runtimes

| Componente | Versão | Método de instalação |
|------------|--------|----------------------|
| Go | `1.26.3` | tarball oficial `go.dev`, por arquitetura |
| Node.js | `24.16.0` (LTS Krypton) | `nvm install` (versão fixada) |
| nvm | `0.39.7` | script oficial (tag fixada) |
| Java (Amazon Corretto) | `21` (LTS) | repo `apt.corretto.aws` |
| Maven | `3.9.6` | `archive.apache.org` (mantém todas as versões) |

## CLIs de IA (instaladas via npm — método oficial de cada uma)

| Componente | Pacote npm | Versão | Comando |
|------------|------------|--------|---------|
| Claude Code | `@anthropic-ai/claude-code` | `2.1.158` | `claude` |
| Gemini CLI | `@google/gemini-cli` | `0.44.1` | `gemini` |
| Codex CLI | `@openai/codex` | `0.135.0` | `codex` |

## CLIs de Cloud / DevOps

| Componente | Versão | Método de instalação |
|------------|--------|----------------------|
| Google Cloud SDK | `570.0.0` | tarball versionado, por arquitetura |
| AWS CLI v2 | `2.34.57` | instalador versionado, por arquitetura |
| GitHub CLI (`gh`) | `2.93.0` | `.deb` versionado, por arquitetura |
| Oracle Cloud CLI (`oci`) | `3.84.0` | **pipx** (venv isolado) |
| Atlassian CLI (`acli`) | `latest` ⚠️ (resolveu p/ `1.3.18-stable`) | binário oficial — **ver exceção abaixo** |

## Ferramentas Google (conta pessoal)

| Componente | Versão | Método de instalação |
|------------|--------|----------------------|
| Himalaya (Gmail) | `1.2.0` | binário GitHub release, por arquitetura (amd64/arm64) |
| gdrive (Drive) | `3.9.1` | binário GitHub release — **só amd64** (sem build arm64 upstream) |
| gcalcli (Calendar) | `4.5.1` | `pipx` (venv isolado) |

## Aplicações Python (via pipx)

| Componente | Versão | Observação |
|------------|--------|------------|
| hermes-agent | `0.15.2` | `pipx install "hermes-agent[all,anthropic,messaging,matrix,wecom,dingtalk,feishu,exa,firecrawl,parallel-web,honcho]"` (Nous Research). Matrix exige `libolm-dev` (camada apt). |
| playwright | `1.60.0` | venv pipx próprio (separado do hermes) |
| playwright-stealth | `2.0.3` | injetado no venv do Playwright (lib) |

## Utilitários

| Componente | Versão | Método |
|------------|--------|--------|
| pm2 | `7.0.1` | `npm -g` (versão fixada) |
| gogcli (`gog`) | `0.19.0` | release GitHub + checksum, por arquitetura |
| HTTPie (`http`) | a do Noble | `apt` |

---

## Exceção de pinagem: Atlassian `acli`

O `acli` é distribuído por um bucket S3 (`acli.atlassian.com`) que **só expõe o canal
`latest`** — não há URL pública por versão. Logo, é o único componente que não é fixado e
pode variar entre builds. Opções para o futuro:

- aceitar o canal `latest` (estado atual, documentado);
- substituir por um mirror interno versionado; ou
- remover a ferramenta se não for essencial (já existe MCP da Atlassian disponível).

A versão efetivamente instalada aparece no `welcome.sh` (`acli --version`).

---

## Pendências conhecidas (restantes)

As correções de arquitetura, Python, pacotes de IA, PATH do Node, checksum do gogcli, posse
do home e instalação do Playwright **foram aplicadas e validadas por build**. Continua em aberto:

1. **Persistência incompleta dos logins de nuvem.** O `docker-compose.yml` ainda não monta
   `~/.config/gcloud`, `~/.aws`, `~/.config/gh` nem `~/.oci`. Até lá, esses logins não
   sobrevivem à recriação do container. (Será tratado junto com a fase de segurança/chaves.)
2. **Tamanho da imagem (~7.3 GB após redução conservadora).** Mais reduções possíveis numa
   próxima rodada: remover o extra `[dev]` do hermes (pytest/ruff/debugpy), remover
   `build-essential` após os builds Python, ou build multi-stage. A decidir.
3. **`hermes-agent`** confirmado como a última estável (0.15.2, Nous Research). Só validar que
   é o agente pretendido — há outros pacotes de nome parecido no PyPI.
4. **Atualizações disponíveis (opcionais):** Maven 3.9.16 e nvm 0.40.x estão disponíveis
   caso queira sair das versões originalmente declaradas. (Go já foi atualizado para 1.26.3
   por exigência do gate de segurança — CVE-2024-24790 e CVE-2025-68121.)
