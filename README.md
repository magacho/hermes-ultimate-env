# Hermes Ultimate Environment

Ambiente de desenvolvimento Docker **portátil, persistente e "baterias incluídas"** para o
**Hermes Agent** — uma *golden image* com linguagens, CLIs de IA, multi-cloud, DevOps e automação.

> **Princípio de arquitetura:** imagem **stateless** (um molde descartável) + dados do usuário
> em **volumes stateful** no host (credenciais, código, sessões). Atualizar a imagem é trivial e
> seguro porque nada do seu estado vive dentro dela.

---

## Quickstart

```bash
# 1. Configure suas chaves de API
cp .env.example .env
$EDITOR .env

# 2. Build + sobe o container
docker compose up --build -d

# 3. Entra no ambiente
docker compose exec hermes bash
```

Seu workspace fica em `/home/hermes/workspaces/`. Toda configuração e sessão é persistente
(ver [docs/CREDENTIALS.md](docs/CREDENTIALS.md)).

### Health & info

O container sobe um servidor leve (porta **8080**) que se auto-descreve:

| Endpoint | Conteúdo |
|----------|----------|
| `GET /health` | status ao vivo (JSON) — também é o `HEALTHCHECK` do Docker |
| `GET /` | página HTML com a release e as versões/bibliotecas instaladas |
| `GET /release.json` | o mesmo inventário em JSON |

```bash
curl localhost:8080/health
# abra http://localhost:8080/ no navegador para ver versões e bibliotecas
```

---

## Documentação

| Documento | Conteúdo |
|-----------|----------|
| [docs/INSTALL.md](docs/INSTALL.md)         | Build local, uso, e pull da imagem do GHCR |
| [docs/TOOLS.md](docs/TOOLS.md)             | Inventário completo de ferramentas |
| [docs/VERSIONS.md](docs/VERSIONS.md)       | Versões instaladas / declaradas |
| [docs/CREDENTIALS.md](docs/CREDENTIALS.md) | Como fornecer chaves e fazer login nas CLIs |
| [docs/SECURITY.md](docs/SECURITY.md)       | Modelo de segurança e gestão de chaves |
| [docs/CICD.md](docs/CICD.md)               | Pipeline de CI/CD, releases e scan de vulnerabilidades |
| [CHANGELOG.md](CHANGELOG.md)               | Histórico de versões |

---

## Estrutura do repositório

```
hermes-ultimate-env/
├── .github/workflows/build-and-push.yml   # CI: build multi-arch → GHCR
├── Dockerfile                              # Definição da imagem
├── docker-compose.yml                      # Orquestra build + volumes
├── welcome.sh                              # MOTD com versões das ferramentas
├── .env.example                            # Template de chaves de API
├── .gitignore
├── docs/                                   # Documentação detalhada
├── agent_data/config/config.yaml           # Config do Hermes (versionada)
└── user_data/                              # SEUS dados (NÃO versionado)
    ├── .ssh/        .gitconfig    .config/
    ├── browser_session/           workspaces/
```

> ⚠️ **Status atual:** existem pendências conhecidas que impedem o build limpo
> (arquitetura, versão do Python, pacotes de IA). Veja a seção *Pendências conhecidas*
> em [docs/VERSIONS.md](docs/VERSIONS.md#pend%C3%AAncias-conhecidas) antes de buildar.

---

## CI/CD e publicação da imagem

Tudo vive no GitHub (código, imagem no GHCR, issues, releases). Resumo:

- **CI** (`ci.yml`): em PRs/push — lint, secret-scan (gitleaks), build, smoke test e
  scan de vulnerabilidades (Trivy, informativo).
- **Release** (`release.yml`): em tags `vX.Y.Z` (estável) ou `bX.Y.Z` (beta) — build
  **multi-arch (amd64+arm64)**, gate de Trivy (**falha em CVE CRITICAL**), push no GHCR e
  GitHub Release (beta = *pre-release*).

```bash
git tag v1.0.0 && git push origin v1.0.0   # release estável
git tag b1.1.0 && git push origin b1.1.0   # release beta
```

Detalhes completos em [docs/CICD.md](docs/CICD.md).

---

## Licença

[MIT](LICENSE) © 2026 Flavio Magacho.
