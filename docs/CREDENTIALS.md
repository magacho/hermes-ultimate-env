# Guia de Configuração de Credenciais

Há três formas de fornecer credenciais ao ambiente. Nenhuma delas deve resultar em segredos
versionados no Git — o [`.gitignore`](../.gitignore) já protege os arquivos sensíveis.

> A análise aprofundada de risco e as recomendações de *hardening* estão em
> [SECURITY.md](SECURITY.md).

## Passo 1 — Chaves de API e tokens (arquivo `.env`)

Método preferido para chaves de API.

```bash
cp .env.example .env
$EDITOR .env   # adicione ANTHROPIC_API_KEY, OPENAI_API_KEY, GEMINI_API_KEY, ...
```

O `docker compose` injeta essas variáveis como ambiente no container. O `.env` **nunca**
deve ser commitado (já está no `.gitignore`).

## Passo 2 — Arquivos de configuração (volume `user_data/`)

Para credenciais baseadas em arquivo (SSH, etc.):

- **Chaves SSH** → `user_data/.ssh/` (ex.: `id_ed25519` + `.pub`). Garanta `chmod 600`
  na chave privada no host. Usadas automaticamente por `git`/`ssh`.
- **Config do Git** → `user_data/.gitconfig` — preencha nome e e-mail para autoria correta
  dos commits.

## Passo 3 — Login interativo (uma vez, dentro do container)

Para a maioria das CLIs de nuvem/DevOps, o primeiro login é interativo. Feito **uma vez**,
a sessão é salva no volume e persiste entre recriações do container.

```bash
docker compose exec hermes bash
```

| CLI | Comando de login |
|-----|------------------|
| Google Cloud | `gcloud auth application-default login` |
| AWS | `aws configure` |
| Oracle Cloud | `oci setup config` |
| GitHub | `gh auth login` |
| Atlassian | `acli auth login` |
| GOG | `gog login <email>` |

> ✅ **Persistência:** o `docker-compose.yml` monta `~/.config` (gcloud, gh, gemini), `~/.aws`
> e `~/.oci` em `user_data/`. Esses logins **sobrevivem** a `docker compose down` + recriação.
> Os arquivos ficam **locais e fora do Git** (ver [SECURITY.md](SECURITY.md)).

### SSH sem expor a chave privada

Em vez de copiar a chave para `user_data/.ssh/`, você pode encaminhar o `ssh-agent` do host —
a chave nunca entra no container. Veja a §5 de [SECURITY.md](SECURITY.md).
