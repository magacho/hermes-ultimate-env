# Guia de Setup — do zero ao funcionando

Onboarding passo a passo do **Hermes Ultimate Environment**: prepara a máquina, sobe o
container, mostra **como obter cada chave de API**, **como autenticar cada CLI**, gera
**chaves SSH** e (opcionalmente) publica a imagem.

> Este guia é o caminho **didático e completo**. Para a versão resumida das credenciais, veja
> [CREDENTIALS.md](CREDENTIALS.md); para o modelo de segurança, [SECURITY.md](SECURITY.md);
> para build/pull e CI/CD, [INSTALL.md](INSTALL.md) e [CICD.md](CICD.md).

> **Modelo de segredos:** _local por usuário, sem compartilhamento_. Cada pessoa cria o próprio
> `.env` e suas credenciais na própria máquina. Entre o time, compartilha-se **apenas** o
> `.env.example` (nomes das variáveis), nunca os valores (ver [SECURITY.md](SECURITY.md)).

---

## 1. Pré-requisitos

- **Docker Engine** 24+ com **Docker Compose v2** (o subcomando `docker compose`, **sem** hífen).
- **~15 GB** livres de disco (a imagem traz SDKs multi-cloud, JDK e o navegador Chromium do
  Playwright).
- (Opcional, para build multi-arch local) `docker buildx` e `qemu-user-static` — ver
  [INSTALL.md](INSTALL.md).

Verifique:

```bash
docker --version           # Docker Engine 24+
docker compose version     # Compose v2 (ex.: v2.x.x)
df -h .                    # confirme ~15 GB livres no disco onde está o repo
```

Se `docker compose version` falhar, você provavelmente tem o Compose v1 (`docker-compose`);
instale o plugin v2 antes de continuar.

---

## 2. Subir do zero

```bash
# 1. Clone o repositório e entre nele
git clone <URL-do-repo> hermes-ultimate-env
cd hermes-ultimate-env

# 2. Crie seu .env a partir do template (preencha na seção 3)
cp .env.example .env

# 3. Build da imagem + sobe o container em background
docker compose up --build -d

# 4. Entre no ambiente
docker compose exec hermes bash
```

A primeira execução **builda a imagem** e pode demorar vários minutos. Seu workspace fica em
`/home/hermes/workspaces/` (montado de `user_data/workspaces/`).

### Checar a página de health/info

O container sobe um servidor leve na porta **8080** que se auto-descreve:

```bash
curl localhost:8080/health        # status ao vivo (JSON) — é o HEALTHCHECK do Docker
# abra http://localhost:8080/     # página HTML com a release e as versões/bibliotecas
```

> `docker compose ps` deve mostrar o container como `healthy` após o `start-period`.
> Detalhes de build/pull em [INSTALL.md](INSTALL.md).

---

## 3. Como obter cada chave de API (arquivo `.env`)

As chaves das **CLIs de IA** entram no `.env`. O `docker compose` as injeta como **variáveis de
ambiente** no container (via `env_file` do `docker-compose.yml`). Variáveis disponíveis no
template ([`.env.example`](../.env.example)):

```dotenv
ANTHROPIC_API_KEY=sk-ant-xxxxxxxx
OPENAI_API_KEY=sk-xxxxxxxx
GEMINI_API_KEY=xxxxxxxx
```

> ⚠️ Essas chaves são **segredos**. Nunca commite o `.env` (já está no `.gitignore`). Se uma
> chave vazar, **revogue-a** no painel de origem e gere outra (ver seção 9).

Edite o `.env` com seu editor preferido:

```bash
$EDITOR .env
```

### Anthropic (`ANTHROPIC_API_KEY`) — usada pelo Claude Code

1. Acesse o **Console da Anthropic**: <https://console.anthropic.com>.
2. Faça login e abra a seção **API Keys** (menu de configurações da conta).
3. Clique em **Create Key**, dê um nome e copie o valor (começa com `sk-ant-`).
4. Cole em `ANTHROPIC_API_KEY` no `.env`.

> A chave aparece **uma única vez** no momento da criação — copie-a imediatamente.

### OpenAI (`OPENAI_API_KEY`) — usada pelo Codex

1. Acesse <https://platform.openai.com>.
2. Vá em **API keys** (menu da conta → *API keys*).
3. Clique em **Create new secret key**, nomeie e copie o valor (começa com `sk-`).
4. Cole em `OPENAI_API_KEY` no `.env`.

### Google Gemini (`GEMINI_API_KEY`) — usada pela Gemini CLI

1. Acesse o **Google AI Studio**: <https://aistudio.google.com>.
2. Clique em **Get API key** (canto superior / menu lateral).
3. Crie a chave (associada a um projeto do Google Cloud) e copie o valor.
4. Cole em `GEMINI_API_KEY` no `.env`.

Depois de editar o `.env`, recarregue o container para aplicar as variáveis:

```bash
docker compose up -d        # recria o container com o .env atualizado
```

---

## 4. Como autenticar cada CLI (login interativo, uma vez)

Para as CLIs de nuvem/DevOps, o **primeiro login é interativo** e feito **dentro do container**.
Feito uma vez, a sessão é gravada nos volumes montados e **persiste** entre `docker compose down`
+ recriação (ver tabela de persistência na seção 7 e em [CREDENTIALS.md](CREDENTIALS.md)).

Entre no container antes de começar:

```bash
docker compose exec hermes bash
```

### GitHub — `gh auth login`

```bash
gh auth login
```

- Escolha **GitHub.com**, protocolo **HTTPS** (ou SSH) e autentique por **browser/device code**
  (a CLI mostra um código de uso único) **ou** colando um **Personal Access Token (PAT)**.
- Para criar um **PAT**: GitHub → **Settings → Developer settings → Personal access tokens →
  Tokens (classic)** (ou *Fine-grained tokens*) → **Generate new token**. Conceda apenas os
  escopos necessários (ex.: `repo`, `read:org`, `workflow`).
- Persiste em `~/.config/gh` (volume `user_data/.config`).

### Google Cloud — `gcloud auth login`

```bash
gcloud auth login                          # login da sua conta (CLI)
gcloud auth application-default login      # credenciais ADC para SDKs/bibliotecas
```

- A CLI gera uma URL; abra-a no navegador do host, autorize e cole o código de volta.
- Persiste em `~/.config/gcloud` (volume `user_data/.config`).

### AWS — `aws configure`

```bash
aws configure
```

- Informe **AWS Access Key ID**, **Secret Access Key**, região default e formato de saída.
- Para gerar as chaves: Console AWS → **IAM → Users → (seu usuário) → Security credentials →
  Create access key**.
- **Least-privilege:** crie um usuário/perfil IAM com apenas as permissões necessárias; evite
  usar credenciais de conta-raiz.
- Persiste em `~/.aws` (volume `user_data/.aws`).

### Oracle Cloud — `oci setup config`

```bash
oci setup config
```

- O assistente gera um **par de chaves de API** (privada + pública) e pede OCID do usuário,
  OCID do tenancy e região.
- Suba a **chave pública** gerada no console OCI: **Perfil do usuário → API Keys → Add API Key**
  (cole/anexe a `.pub` gerada).
- Persiste em `~/.oci` (volume `user_data/.oci`).

### Atlassian — `acli auth login`

```bash
acli auth login
```

- Requer um **API token**. Crie em <https://id.atlassian.com> → **Security → API tokens →
  Create API token**. Copie o valor (aparece uma vez).
- Informe o e-mail/site e o token quando solicitado.
- Persiste em `~/.config` (volume `user_data/.config`).

### GOG — `gog login <email>`

```bash
gog login seu-email@exemplo.com
```

- Siga o fluxo interativo da CLI. Persiste em `~/.config` (volume `user_data/.config`).

> ✅ **Resumo de persistência:** o `docker-compose.yml` monta `~/.config` (gcloud, gh, gemini,
> acli, gog), `~/.aws` e `~/.oci` em `user_data/`. Esses logins sobrevivem à recriação do
> container e ficam **locais e fora do Git**.

---

## 5. Chaves SSH

Para usar `git`/`ssh` por SSH dentro do container, há duas opções.

### Opção A — Gerar e montar a chave (simples)

```bash
# Gere o par de chaves (no host ou dentro do container)
ssh-keygen -t ed25519 -C "seu-email@exemplo.com" -f user_data/.ssh/id_ed25519

# Garanta as permissões corretas da chave privada (no host)
chmod 600 user_data/.ssh/id_ed25519
chmod 644 user_data/.ssh/id_ed25519.pub
```

- A pasta `user_data/.ssh/` é montada em `~/.ssh` no container — `git`/`ssh` a usam
  automaticamente.
- **Adicione a chave pública no GitHub:** copie o conteúdo de `user_data/.ssh/id_ed25519.pub`
  e cole em GitHub → **Settings → SSH and GPG keys → New SSH key**.
- Teste dentro do container: `ssh -T git@github.com`.

### Opção B — `ssh-agent` forwarding (recomendado)

Em vez de copiar a chave privada para dentro do container, encaminhe o **`ssh-agent` do host**
— a chave nunca toca o disco do container. Configuração no `docker-compose.yml` e detalhes na
**§5 de [SECURITY.md](SECURITY.md)**.

---

## 6. (Opcional) Publicar a imagem no Docker Hub

Por padrão a release publica no **GHCR** sem configuração (usa o `GITHUB_TOKEN`). O **Docker Hub**
é opcional e só roda se você definir as variáveis abaixo.

1. Crie uma conta e um **repositório** no Docker Hub (<https://hub.docker.com>) — o repo precisa
   existir **antes** da primeira release.
2. Gere um **Access Token** (Read & Write): <https://app.docker.com> → **Account settings →
   Personal access tokens** → criar token com permissão de escrita. Copie o valor.
3. Configure no GitHub em **Settings → Secrets and variables → Actions** do repositório:

   | Tipo | Nome | Valor |
   |------|------|-------|
   | Variable | `DOCKERHUB_REPO` | repositório destino, ex.: `magacho/hermes-ultimate-env` |
   | Secret | `DOCKERHUB_USERNAME` | seu usuário do Docker Hub |
   | Secret | `DOCKERHUB_TOKEN` | o Access Token gerado acima (escrita) |

4. Lance uma release com tag `vX.Y.Z` (estável) ou `bX.Y.Z` (beta). O fluxo completo de release
   (gate de Trivy, multi-arch, tags publicadas) está em [CICD.md](CICD.md).

> Enquanto `DOCKERHUB_REPO` não estiver definida, o pipeline **pula** o Docker Hub e publica só
> no GHCR, sem falhar.

---

## 7. Onde cada credencial fica

A imagem é **stateless**: nenhum segredo entra nela. Tudo vive em volumes locais (host), ignorados
pelo Git (`.gitignore`) e pelo build (`.dockerignore`) — ver [SECURITY.md](SECURITY.md).

| Tipo de credencial | Arquivo / volume local | Como chega ao container |
|--------------------|------------------------|-------------------------|
| Chaves de API (Anthropic, OpenAI, Gemini) | `.env` | `env_file` do compose → variáveis de ambiente |
| Chave SSH | `user_data/.ssh/` | volume montado em `~/.ssh` |
| Login GitHub (`gh`) | `user_data/.config/gh/` | volume montado em `~/.config` |
| Login Google Cloud (`gcloud`) | `user_data/.config/gcloud/` | volume montado em `~/.config` |
| Login Gemini CLI | `user_data/.config/` | volume montado em `~/.config` |
| Login Atlassian (`acli`) / GOG (`gog`) | `user_data/.config/` | volume montado em `~/.config` |
| Login AWS (`aws`) | `user_data/.aws/` | volume montado em `~/.aws` |
| Login Oracle Cloud (`oci`) | `user_data/.oci/` | volume montado em `~/.oci` |
| Identidade do Git | `user_data/.gitconfig` | volume montado em `~/.gitconfig` |

---

## 8. Verificação

Confirme que o ambiente está completo e funcional:

```bash
# Dentro do container:
bash /etc/welcome.sh              # MOTD com as versões de todas as ferramentas

# Página de info (do host ou navegador):
curl localhost:8080/health        # {"status": ...}
# http://localhost:8080/          # release + inventário de versões/bibliotecas

# Teste 1-2 CLIs (após autenticar — seções 3 e 4):
gh auth status                    # mostra a conta GitHub autenticada
claude --version                  # CLI de IA respondendo
aws sts get-caller-identity       # confirma credenciais AWS (se configuradas)
```

---

## 9. Boas práticas de segurança

- **Rotacione tokens** periodicamente e use **expiração** quando o provedor permitir.
- **Nunca compartilhe** o `.env` nem o conteúdo de `user_data/` — compartilhe só o `.env.example`.
- **Least-privilege:** conceda a cada credencial (PAT, IAM, API token) apenas o escopo mínimo.
- **Revogue imediatamente** qualquer segredo que vazar (no painel de origem) e gere um novo.
- Rode o **checklist pré-commit** da [SECURITY.md](SECURITY.md) antes de versionar qualquer coisa.

Para o modelo de ameaça completo, riscos residuais e opções de hardening, veja
[SECURITY.md](SECURITY.md).
