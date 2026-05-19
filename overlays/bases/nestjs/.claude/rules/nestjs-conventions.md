---
description: NestJS module conventions, provider scopes, lifecycle, testing
globs:
  - "src/**/*.module.ts"
  - "src/**/*.controller.ts"
  - "src/**/*.service.ts"
  - "test/**/*.ts"
alwaysApply: false
---

# NestJS Conventions

## Module boundaries

- One module per bounded context. Modules group controllers, services, and providers.
- Modules export only what other modules need — keep the public surface small.
- The root `AppModule` imports feature modules; it shouldn't declare business logic.

## Provider scopes

- Default scope is `SINGLETON` — one instance per app. Don't store per-request state there.
- `Scope.REQUEST` only when you need per-request state (auth context, tenant). It's slower (provider tree rebuilds per request).
- `Scope.TRANSIENT` is almost never what you want.

## Dependency injection

- Inject via constructor. Avoid `@Inject(TOKEN)` unless you're using a custom token.
- One responsibility per service. If a service has more than ~5 injected dependencies, it's doing too much.

## Lifecycle hooks

- `OnModuleInit` for startup work that needs DI.
- `OnModuleDestroy` for cleanup (close DB pools, stop intervals).
- Don't run startup work in module constructors — use the lifecycle hooks.

## Configuration

- Use `@nestjs/config` with a typed config schema.
- Validate env at startup with `Joi` or `class-validator`. Fail fast if a required var is missing.

## Testing

- Unit tests with `Test.createTestingModule()` — inject mocks for dependencies.
- E2E tests with `@nestjs/testing` + `supertest`. Use a separate test database, never the dev one.
- The `code-review` hook flags tests that hit live external services.

## Common pitfalls

- **Circular imports** — restructure modules; don't reach for `forwardRef` reflexively.
- **Async providers without `await`** — declarative providers (`useFactory`) can be async, but you must `await` the factory.
- **Decorator order matters** for stacking guards/interceptors — apply controller-level first, then method-level.
