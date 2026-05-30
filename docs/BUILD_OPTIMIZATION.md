# Avaliação de performance de build

> Contexto da issue: **"Avaliar o processo de build e estudar otimizações (demora > 30 min)"**.
> Escopo desta entrega: **diagnóstico + proposta**, sem implementação.

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

- **Build duplicado no release**:
  - primeiro build `amd64` para scan/gate;
  - segundo build multi-arch (`amd64+arm64`) para push.
- **Build multi-arch com QEMU** para `arm64`, que costuma aumentar bastante o tempo.
- **Dockerfile monolítico e pesado** (muitas instalações de runtimes/CLIs), aumentando custo de cold build.
- **Dependência de downloads externos** (Go, Maven, gcloud, AWS CLI, npm, pipx, Playwright/browser), com variabilidade de rede.

## Proposta de otimização (sem implementar agora)

### Fase 1 — Ganhos rápidos (baixo risco)

1. **Adicionar medição de tempo por etapa no workflow** (telemetria simples em resumo de job).
2. **Ajustar cache Buildx por escopo/arquitetura** (`scope` dedicado para release, branch e plataforma).
3. **Evitar rebuild desnecessário de amd64 no release** (reaproveitar artefato/imagem intermediária quando possível).

> Meta esperada da fase 1: reduzir variabilidade e obter baseline confiável para comparar otimizações.

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
