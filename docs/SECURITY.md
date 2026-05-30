# Segurança e Gestão de Chaves

Este documento descreve o modelo de segurança do ambiente, como as credenciais são tratadas
e o processo de chaves adotado.

**Modelo de chaves escolhido: _local por usuário, sem compartilhamento_.** Cada pessoa cria e
mantém o próprio `.env` e suas credenciais na própria máquina. Segredos **nunca** são
versionados nem embutidos na imagem. Entre integrantes do time, compartilha-se apenas o
**`.env.example`** (nomes das variáveis), nunca os valores.

---

## 1. Modelo de ameaça

### No escopo (o que este projeto protege)
- **Vazamento de segredos para o Git/GitHub.** `.gitignore` + `.dockerignore` impedem que
  `.env`, chaves SSH, sessões de navegador e configs de nuvem entrem no repositório ou no
  contexto de build.
- **Segredos embutidos na imagem.** A imagem é *stateless*: nenhum segredo é copiado para
  dentro dela. Credenciais entram só em runtime (variáveis de ambiente e volumes locais).
- **Reprodutibilidade / proveniência.** Versões fixadas e checksum no gogcli reduzem o risco
  de "puxar" um artefato adulterado. Ver [VERSIONS.md](VERSIONS.md).

### Fora do escopo (assumimos confiança)
- A **máquina host** e o **usuário local** são confiáveis. Quem tem acesso ao host tem acesso
  aos volumes e ao `.env` — aceitável para um sandbox de desenvolvimento individual.
- Não há isolamento contra um operador malicioso da própria máquina.

---

## 2. Como as credenciais entram no ambiente

| Tipo | Onde fica | Como chega ao container |
|------|-----------|-------------------------|
| Chaves de API (Anthropic, OpenAI, Gemini…) | `.env` (local, gitignored) | `env_file` do compose → variáveis de ambiente |
| Chave SSH | `user_data/.ssh/` (local) | volume montado em `~/.ssh` |
| Login de nuvem (gcloud/gh/gemini) | `user_data/.config/` (local) | volume montado em `~/.config` |
| Login AWS | `user_data/.aws/` (local) | volume montado em `~/.aws` |
| Login OCI | `user_data/.oci/` (local) | volume montado em `~/.oci` |

Todos esses caminhos são **ignorados pelo Git** e pelo build. O fluxo completo de setup está
em [CREDENTIALS.md](CREDENTIALS.md).

---

## 3. Riscos residuais e mitigações

| # | Risco | Estado / mitigação |
|---|-------|--------------------|
| 1 | **Chaves de API visíveis em `docker inspect` / `/proc/<pid>/environ`** | Aceito no modelo local-por-usuário (host confiável). Quem precisar de mais isolamento pode migrar para Docker secrets ou um cofre — fora do escopo atual. |
| 2 | **`sudo NOPASSWD:ALL` para o usuário `hermes`** | Conveniência de sandbox de dev. Root no container ≠ root no host (usuário não-root + namespaces), mas amplia a superfície. Hardening opcional: `no-new-privileges` (ver §4) — desativa o sudo. |
| 3 | **Instaladores via `curl \| bash` (nvm, acli)** | Reduzido: versões fixadas; gogcli tem verificação de **checksum sha256**. nvm usa tag fixada; `acli` vem do canal oficial `latest` (sem URL versionada — ver VERSIONS.md). |
| 4 | **Chave SSH privada montada no container** | Funciona, mas preferir **`ssh-agent` forwarding** (ver §5) para a chave nunca entrar no container. |
| 5 | **Vazamento via contexto de build** | Mitigado pelo `.dockerignore` (exclui `user_data/`, `.env`, `.git`). |
| 6 | **Servidor de info expõe o inventário de versões na porta 8080 (`0.0.0.0`)** | Escolhido para acesso em rede. É *info disclosure* leve (versões instaladas → recon). Não serve segredos. Para restringir: `HERMES_INFO_BIND=127.0.0.1` ou mapear `127.0.0.1:8080:8080` no compose. |

---

## 4. Hardening opcional do runtime

O `docker-compose.yml` traz, comentado, a opção:

```yaml
# security_opt:
#   - no-new-privileges:true
```

Impede escalonamento de privilégios, **mas desativa o `sudo`** do usuário `hermes`. Habilite
apenas se você não precisar instalar pacotes em runtime dentro do container.

Outras opções (não habilitadas por padrão) para ambientes mais sensíveis:
- `read_only: true` + `tmpfs` para `/tmp` — raiz imutável.
- `cap_drop: [ALL]` e adicionar só as capabilities necessárias.
- Limites de `mem_limit` / `pids_limit`.

---

## 5. SSH: recomendação

Em vez de montar a chave privada no container, prefira **encaminhar o agente SSH** do host,
para a chave nunca tocar o disco do container:

```yaml
# no docker-compose.yml, no serviço hermes:
volumes:
  - ${SSH_AUTH_SOCK}:/ssh-agent
environment:
  SSH_AUTH_SOCK: /ssh-agent
```

(Mantenha a montagem de `user_data/.ssh` apenas se precisar de `known_hosts`/config.)

---

## 6. Proveniência e assinatura da imagem

- Prefira consumir por **digest fixo** (`@sha256:…`) em vez de só `:latest`.
- O CI publica via `GITHUB_TOKEN` com escopo `packages: write` — sem segredos extras.
- **Assinatura:** toda imagem de release é assinada com **cosign keyless** usando o OIDC do
  GitHub Actions (`id-token: write`), por digest, em cada registry (GHCR e Docker Hub). Não há
  chave privada armazenada no repositório.

### Como verificar a assinatura (consumidor)

```bash
IMAGE=ghcr.io/<owner>/<repo>:latest      # ou docker.io/<DOCKERHUB_REPO>:latest

cosign verify "$IMAGE" \
  --certificate-identity-regexp "^https://github.com/<owner>/<repo>/.github/workflows/release.yml@refs/tags/.+$" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"
```

Para máxima imutabilidade, verifique por digest:

```bash
cosign verify "ghcr.io/<owner>/<repo>@sha256:<digest>" \
  --certificate-identity-regexp "^https://github.com/<owner>/<repo>/.github/workflows/release.yml@refs/tags/.+$" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"
```

---

## 7. Checklist pré-commit

- [ ] `git status` não lista `.env`, `*.key`, `*.pem`, conteúdo de `user_data/.ssh/`,
      `user_data/.aws/`, `user_data/.oci/`, `user_data/.config/` ou `browser_session/`.
- [ ] `user_data/.gitconfig` não contém identidade real que você não queira pública.
- [ ] Nenhum segredo embutido no `Dockerfile`, no `docker-compose.yml` ou no histórico de commits.
- [ ] `docker history <imagem>` não revela segredos em camadas (a imagem não deve conter `.env`).
