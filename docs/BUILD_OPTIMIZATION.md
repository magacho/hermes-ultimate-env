# Avaliação de performance de build

> Contexto da issue: **"Avaliar o processo de build e estudar otimizações (demora > 30 min)"**.

> **Status (atualizado):** decisão tomada e **implementada** — split em jobs nativos paralelos
> (amd64 + arm64) com merge de manifesto. A "telemetria por etapa" foi **descartada** (o GitHub
> Actions já expõe a duração por passo nativamente). Ver "Decisão e implementação" no fim.

## Resumo executivo

O tempo acima de 30 minutos acontece principalmente no workflow de **Release**.
Analisando execuções recentes:

- **Release (run #3)**: ~**46,6 min** (tag `b0.1.0`)
- **CI (push em `main`)**: ~**5–10 min**

Ou seja: o gargalo é o fluxo de publicação multi-arquitetura (não o CI de PR/push).

## Evidências observadas (Release bem-sucedida)

No run `26683001893`, os passos mais caros foram:

1. `Build (amd64) para scan`: ~**6m14s**
2. `Build & push (linux/amd64, linux/arm64)`: ~**34m17s**
3. Trivy (SARIF + gate): ~**5m26s** no total

### Diagnóstico objetivo

Os principais fatores de lentidão são:

- **Build multi-arch com QEMU** para `arm64` — **fator dominante** (a maior parte dos ~34min
  do passo de push é a emulação do arm64).
- **Build amd64 para scan + build multi-arch para push** — fator **secundário**: o build
  multi-arch reaproveita as camadas amd64 via cache `type=gha`, então não é uma duplicação
  cheia; o custo real está no arm64 emulado.
- **Dockerfile monolítico e pesado** (muitas instalações de runtimes/CLIs), aumentando custo de cold build.
- **Dependência de downloads externos** (Go, Maven, gcloud, AWS CLI, npm, pipx, Playwright/browser), com variabilidade de rede.

## Proposta de otimização (sem implementar agora)

### Fase 1 — Ganhos rápidos (baixo risco)

1. ~~**Adicionar medição de tempo por etapa no workflow** (telemetria).~~ **Descartado** — o
   GitHub Actions já mostra a duração de cada passo na UI e via `gh run view`; instrumentar
   isso no workflow só duplicaria dado existente.
2. **Ajustar cache Buildx por escopo/arquitetura** (`scope` dedicado por plataforma). ✅ Feito
   (scopes `amd64`/`arm64` separados).
3. **Evitar rebuild desnecessário de amd64** — já mitigado pelo cache `type=gha`.

### Fase 2 — Maior impacto em tempo total

1. **Separar build por arquitetura em jobs paralelos**:
   - job `amd64` (runner x86 nativo)
   - job `arm64` (runner ARM nativo, sem emulação)
   - job final monta e publica manifesto multi-arch.
2. **Reduzir custo do scan de segurança no release**:
   - manter gate CRITICAL,
   - mas evitar pipeline com dois builds completos quando não necessário.

> Meta esperada da fase 2: reduzir release para algo na faixa de ~15–25 min (dependendo do runner ARM).

### Fase 3 — Estrutural (imagem)

1. **Quebrar a imagem em camadas/base reutilizável** (base "toolchain" + camada final do ambiente).
2. **Reavaliar componentes mais pesados e frequência de atualização** (ex.: Playwright + Chromium).
3. **Avaliar build multi-stage para reduzir custo de rebuild e tamanho final**.

## Backlog sugerido (issues derivadas)

1. `build: adicionar métricas de duração por etapa no release`
2. `ci: revisar estratégia de cache buildx para release multi-arch`
3. `release: separar build amd64/arm64 em jobs paralelos`
4. `infra: avaliar runner arm64 nativo para eliminar QEMU`
5. `dockerfile: estudar split em imagem base + camada final`

## Critérios de sucesso sugeridos

- P95 do workflow de release **< 30 min**
- Build multi-arch com variação controlada entre execuções
- Sem regressão no gate de segurança (Trivy CRITICAL)

---

## Decisão e implementação

**Escolha:** separar o build por arquitetura em **jobs nativos paralelos** (eliminando o QEMU),
com um job de merge. Implementado no `release.yml`:

- `meta` → resolve tag/canal/imagens.
- `build-amd64` (runner `ubuntu-latest`, x86 nativo) → **Trivy SARIF + gate CRITICAL** e, se
  passar, **push por digest** (GHCR + Docker Hub).
- `build-arm64` (runner **`ubuntu-24.04-arm` nativo**, sem emulação) → push por digest, **em
  paralelo** com o amd64.
- `merge` → `docker buildx imagetools create` monta o manifesto multi-arch em cada registry,
  **assina com cosign keyless** (por digest do índice) e cria o **GitHub Release**.

**O que NÃO foi feito (e por quê):**
- Telemetria de tempo por etapa — redundante (dado já existe no Actions).

**Pendente / próximo (issue #1):** multi-stage e split de imagem base → foco em **tamanho**
(não em tempo; o tempo já é resolvido pelo runner nativo).

> Validação: comparar a duração do primeiro release nesse modelo (esperado ~10–18 min) com a
> baseline de ~45 min.
