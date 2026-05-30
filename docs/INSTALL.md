# Instalação e Uso

## Pré-requisitos

- **Docker Engine** 24+ com **Docker Compose v2** (`docker compose`, sem hífen).
- Para build **multi-arch** local: `docker buildx` (já incluso no Docker moderno) e,
  para emular outra arquitetura, `qemu-user-static`.
- ~10–15 GB livres de disco (a imagem é grande: multi-cloud SDKs + navegadores Playwright + JDK).

Verifique:

```bash
docker --version
docker compose version
docker buildx version
```

---

## Opção A — Build local com Docker Compose (recomendado para uso diário)

```bash
# 1. Chaves de API
cp .env.example .env && $EDITOR .env

# 2. Build + sobe em background
docker compose up --build -d

# 3. Acessa o shell do ambiente
docker compose exec hermes bash

# Parar / remover (os volumes em user_data/ e agent_data/ permanecem no host)
docker compose down
```

A primeira credencial interativa de cada CLI de nuvem deve ser feita uma vez dentro
do container — veja [CREDENTIALS.md](CREDENTIALS.md).

---

## Opção B — Build manual com buildx (multi-arch)

```bash
# Cria um builder com suporte multi-plataforma (uma vez)
docker buildx create --name hermes --use --bootstrap

# Build para amd64 + arm64. Para multi-arch é preciso --push (registry)
# ou --load apenas para UMA plataforma local.
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/<owner>/hermes-ultimate-env:dev \
  --push .
```

> Build local de **uma** arquitetura só (carrega no Docker local):
> ```bash
> docker buildx build --platform linux/amd64 -t hermes-ultimate-env:local --load .
> ```

---

## Opção C — Pull da imagem publicada no GHCR

Após o CI publicar (ver abaixo):

```bash
docker pull ghcr.io/<owner>/hermes-ultimate-env:latest
# ou uma versão fixa
docker pull ghcr.io/<owner>/hermes-ultimate-env:v1.0.0
```

Para usar a imagem publicada com o compose, troque o bloco `build:` por
`image: ghcr.io/<owner>/hermes-ultimate-env:latest` no `docker-compose.yml`.

---

## CI/CD — Publicação automática no GHCR

O workflow `.github/workflows/build-and-push.yml`:

- **Dispara** em: criação de *tag* `v*`, publicação de *release*, ou manualmente
  (`workflow_dispatch`). **Não** roda a cada push para `main`, para evitar falhas ruidosas
  enquanto as pendências de build não estão resolvidas.
- **Builda** para `linux/amd64` e `linux/arm64` via `buildx` + QEMU.
- **Publica** no GHCR (`ghcr.io/<owner>/<repo>`) com tags derivadas da versão
  (`X.Y.Z`, `X.Y`, `latest`).
- **Autentica** com o `GITHUB_TOKEN` automático (permissão `packages: write`) — nenhum
  segredo adicional é necessário para publicar no GHCR do próprio repositório.

### Como lançar uma versão

```bash
git tag v1.0.0
git push origin v1.0.0
# (ou crie uma Release pela UI do GitHub)
```

> ⚠️ O build multi-arch só terá sucesso depois de resolver a pendência de arquitetura
> do `Dockerfile` (binários ARM64 fixos). Veja [VERSIONS.md](VERSIONS.md#pend%C3%AAncias-conhecidas).
