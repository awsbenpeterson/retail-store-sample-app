# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build System

This is an Nx monorepo using Yarn 4. All build/test/serve commands go through nx:

```bash
yarn install                          # Install root dependencies
yarn nx build <component>             # Build a single service
yarn nx test <component>              # Unit tests
yarn nx test:integration <component>  # Integration tests (uses testcontainers)
yarn nx serve <component>             # Run locally on port 8080
yarn nx lint <component>              # Lint
yarn nx container <component>         # Build container image

# Bulk operations on all services
yarn nx run-many -t test --projects=tag:service
yarn nx run-many -t container --projects=tag:service
```

Components: `ui`, `catalog`, `cart`, `orders`, `checkout`, `load-generator`, `e2e`

### Per-service build details

| Service | Language | Build | Test | Lint |
|---------|----------|-------|------|------|
| ui, cart, orders | Java 21 / Spring Boot | `./mvnw package` | `./mvnw test -DexcludedGroups=integration` | `./mvnw checkstyle:checkstyle` |
| catalog | Go | `go build -o dist/main main.go` | `go test -v ./test/...` (integration only) | — |
| checkout | Node.js / NestJS | `nest build` | `jest --config ./test/jest-e2e.json` (integration) | `eslint` |

Java integration tests use `-Dgroups=integration` flag. Checkout requires `yarn install` in `src/checkout/` before build.

### Running the full app locally

```bash
yarn nx compose-app:up     # Docker Compose all services (builds locally)
yarn nx compose-app:down   # Tear down

# Single service with its dependencies
yarn nx compose:up <component>
```

## Pre-commit Hooks

Husky runs `lint-staged` on commit which applies:
- **prettier** on js/ts/json/md/yaml/java/xml files
- **gofmt** on Go files
- **terraform fmt** + **tflint** on .tf files
- Changes to `samples/` trigger `yarn nx run-many -t update-samples --projects=tag:sample`

## Architecture

Polyglot microservices retail application (educational, not production). Services communicate via HTTP REST.

- **UI** (Java/Spring Boot) — Store frontend, calls all backend services
- **Catalog** (Go/Gin) — Product catalog API, backed by MySQL/SQLite
- **Cart** (Java/Spring Boot) — Shopping cart API, backed by DynamoDB or Redis
- **Orders** (Java/Spring Boot) — Order management API, backed by MariaDB/MySQL with RabbitMQ
- **Checkout** (Node.js/NestJS) — Orchestrates the checkout flow, calls cart/orders/catalog

All services expose Prometheus metrics and OpenTelemetry OTLP tracing. Structured JSON logging throughout.

## Terraform

`terraform/lib/` contains reusable modules. Deployment patterns in `terraform/eks/`, `terraform/ecs/`, `terraform/apprunner/`. Format with `terraform fmt`.

## Development Environment

Use `mise install` to set up all tool versions (Java 21, Node 22, Go 1.25, Terraform, kubectl, Helm, etc.) defined in `.mise.toml`.

## Code Style

- Java: Checkstyle config at `src/misc/style/java/checkstyle.xml`
- Prettier handles Java, XML, JSON, YAML, Markdown, JS/TS formatting (plugins: prettier-plugin-java, @prettier/plugin-xml)
- Go: standard gofmt
