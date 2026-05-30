# Inventário de Ferramentas

Tudo que a imagem inclui, por categoria. As versões exatas estão em [VERSIONS.md](VERSIONS.md);
a coluna **Como é instalado** é relevante para reprodutibilidade e segurança (ver
[SECURITY.md](SECURITY.md)).

## Core e Automação

| Ferramenta | Comando | Como é instalado |
|------------|---------|------------------|
| Hermes Agent | (entrypoint do pacote) | `pipx install "hermes-agent[all,anthropic,messaging,matrix,wecom,dingtalk,feishu,exa,firecrawl,parallel-web,honcho]"` |
| ↳ Integrações | — | modelos (Anthropic/OpenAI), MCP, Web/FastAPI, Google, YouTube, **mensageria** (Telegram, Discord, Slack, Matrix, WeCom, DingTalk, Feishu), **busca/scraping** (Exa, Firecrawl, Parallel-web), **Honcho** |
| Playwright + stealth | `playwright` | venv pipx próprio + `playwright install --with-deps chromium` |

## Linguagens e Runtimes

| Ferramenta | Comando | Como é instalado |
|------------|---------|------------------|
| Python | `python3` (3.12) | `apt` |
| Node.js (LTS, fixado) | `node` / `npm` | `nvm install <versão fixada>` |
| Go | `go` | tarball oficial `go.dev`, por arquitetura |
| Java (Amazon Corretto 21) | `java` | repo `apt.corretto.aws` |
| Maven | `mvn` | `archive.apache.org` |

## CLIs de IA / LLMs (via npm — método oficial)

| Ferramenta | Comando | Como é instalado |
|------------|---------|------------------|
| Claude Code | `claude` | `npm -g @anthropic-ai/claude-code@…` |
| Codex | `codex` | `npm -g @openai/codex@…` |
| Gemini | `gemini` | `npm -g @google/gemini-cli@…` |

> As três autenticam por variável de ambiente / login próprio — ver [CREDENTIALS.md](CREDENTIALS.md).

## CLIs de Cloud

| Ferramenta | Comando | Como é instalado |
|------------|---------|------------------|
| Google Cloud SDK | `gcloud` | tarball versionado, por arquitetura |
| AWS CLI v2 | `aws` | instalador versionado, por arquitetura |
| Oracle Cloud CLI | `oci` | `pipx install oci-cli==…` (isolado) |

## CLIs de DevOps

| Ferramenta | Comando | Como é instalado |
|------------|---------|------------------|
| GitHub CLI | `gh` | `.deb` versionado, por arquitetura |
| Atlassian CLI | `acli` | binário oficial canal `latest` ⚠️ (ver VERSIONS.md) |

## Google (conta pessoal)

| Ferramenta | Comando | Como é instalado |
|------------|---------|------------------|
| Gmail (Himalaya) | `himalaya` | binário oficial (GitHub release), por arquitetura |
| Calendar (gcalcli) | `gcalcli` | `pipx install gcalcli` |
| Drive (gdrive) | `gdrive` | binário oficial (GitHub release) — **só amd64** |

## Utilitários

| Ferramenta | Comando | Como é instalado |
|------------|---------|------------------|
| HTTPie | `http` | `apt` |
| GOG Client | `gog` | release GitHub + checksum, por arquitetura |
| PM2 | `pm2` | `npm -g` (versão fixada) |
| git, openssh, curl, wget, gnupg, unzip, build-essential | — | `apt` |

---

O script [`welcome.sh`](../welcome.sh) imprime as versões dessas ferramentas no login do shell
(MOTD), servindo como verificação rápida de que o ambiente está completo.
