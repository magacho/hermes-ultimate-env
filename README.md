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

---

## Documentação

| Documento | Conteúdo |
|-----------|----------|
| [docs/INSTALL.md](docs/INSTALL.md)         | Build local, uso, e pull da imagem do GHCR |
| [docs/TOOLS.md](docs/TOOLS.md)             | Inventário completo de ferramentas |
| [docs/VERSIONS.md](docs/VERSIONS.md)       | Versões instaladas / declaradas |
| [docs/CREDENTIALS.md](docs/CREDENTIALS.md) | Como fornecer chaves e fazer login nas CLIs |
| [docs/SECURITY.md](docs/SECURITY.md)       | Modelo de segurança e gestão de chaves |
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

## Publicação da imagem (GHCR)

O workflow em `.github/workflows/build-and-push.yml` builda a imagem **multi-arch
(amd64 + arm64)** e publica no **GitHub Container Registry** ao criar uma *tag* `v*`
ou uma *release*. Detalhes em [docs/INSTALL.md](docs/INSTALL.md).

---

## Licença

[MIT](LICENSE) © 2026 Flavio Magacho.
