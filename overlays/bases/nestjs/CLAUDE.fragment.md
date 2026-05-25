## {{STACK}}

- **Runtime:** Node.js v25 (see `.nvmrc`)
- **Framework:** NestJS ^10 (modules, controllers, services, DI)
- **Language:** TypeScript with decorators (`experimentalDecorators`, `emitDecoratorMetadata` required)
- **Tests:** Jest + `@nestjs/testing` + Supertest (e2e)
- **Lint / format:** ESLint flat config + `typescript-eslint` + Prettier
- **Type:** HTTP REST API (no UI), opinionated enterprise structure

## {{COMMANDS}}

### Dev loop
- `npm run dev` — `nest start --watch` (HMR-style hot reload)
- `npm test` — Jest unit tests
- `npm run test:e2e` — Supertest against the full app, separate config
- `npm run test:coverage` — coverage report (target ≥ 80%)

### Quality
- `npm run lint` — ESLint
- `npm run lint:fix` — auto-fix what's safe
- `npm run format` — Prettier write
- `npm run format:check` — Prettier check only
- `npm run build` — `nest build`
- `npm run validate` — local gate (lint + format + build + test) = pre-commit hook minus AI steps

### Preflight
- `npm run check-setup` — verify Node version, `claude` CLI, plugins, hook wiring

### Review
- `npm run review` — manual `/code-review` on the last commit

### Maintenance
- `npm run deps:audit` — production-only `npm audit`
- `npm run deps:outdated` — list outdated packages

## {{ARCHITECTURE}}

### Tree

```
src/
├── main.ts                      ← Bootstrap (global pipes, filters, interceptors, app.listen)
├── app.module.ts                ← Root module — composes feature modules
├── modules/<feature>/           ← One folder per bounded context
│   ├── <feature>.module.ts
│   ├── <feature>.controller.ts  ← Thin: parse request → call service → return
│   ├── <feature>.service.ts     ← Business logic; one responsibility
│   └── dto/                     ← class-validator + class-transformer DTOs
└── common/                      ← Cross-cutting filters, guards, interceptors, pipes
test/                            ← E2E tests
```

### What goes where

| Adding... | Lives in |
|---|---|
| A new bounded context | `src/modules/<feature>/` (a fresh module) |
| A new endpoint inside an existing module | `src/modules/<feature>/<feature>.controller.ts` |
| Business logic for an endpoint | `src/modules/<feature>/<feature>.service.ts` |
| Request/response shapes | `src/modules/<feature>/dto/` |
| Authentication or authorisation | `src/common/guards/<name>.guard.ts` |
| Response wrapping (logging, transform) | `src/common/interceptors/<name>.interceptor.ts` |
| A global exception filter | `src/common/filters/<name>.filter.ts` |
| Unit tests | Co-located: `foo.service.ts` → `foo.service.spec.ts` |
| E2E tests | `test/<feature>.e2e-spec.ts` |

### Base-specific notes

- See `.claude/rules/api.md` for REST conventions and DTO patterns.
- See `.claude/rules/typescript.md` for strict TS (decorator metadata required — don't drop it).
- See `.claude/rules/nestjs-conventions.md` for module boundaries, provider scopes, lifecycle hooks, exception filters.
- Controllers are thin: parse the request, call a service, return a result. No business logic.
- DTOs at the boundary — every body and query param has a class with `class-validator` decorators. Enable `ValidationPipe` globally with `whitelist: true, transform: true, forbidNonWhitelisted: true`.

## {{ANTIPATTERNS}}

- ❌ Business logic in controllers. Controllers parse and delegate; the work happens in services.
- ❌ Removing `reflect-metadata` from `main.ts` — DI breaks instantly. Keep it as the first import.
- ❌ Setting `Scope.REQUEST` reflexively. It rebuilds the provider tree per request — only use when you genuinely need per-request state.
- ❌ Auth checks inside interceptors. Auth belongs in **guards**. Interceptors wrap responses; guards decide if the request proceeds.
- ❌ Validation in service methods that DTOs should have caught. If the DTO is incomplete, fix the DTO.
- ❌ `forwardRef` to "fix" a circular import. Restructure the modules instead — `forwardRef` papers over a design smell.
- ❌ Async providers via `useFactory` without `await`. Declarative async factories must be awaited.
- ❌ Hitting live external services in unit tests. Mock at the service boundary; reserve e2e for real integrations.
- ❌ Returning raw entities from controllers. Map to response DTOs — entities leak fields you didn't intend to expose.
