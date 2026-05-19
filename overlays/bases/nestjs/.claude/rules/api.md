---
description: NestJS API conventions — controllers, services, DTOs, validation, error handling
globs:
  - "src/**/*.controller.ts"
  - "src/**/*.service.ts"
  - "src/**/*.dto.ts"
alwaysApply: false
---

# API Rules (NestJS)

## Controllers are thin

- Controllers parse the request, call a service, return the result. No business logic.
- All side effects, persistence, and orchestration belong in `*.service.ts`.
- A controller method longer than 10 lines is a smell.

## DTOs at the boundary

- Every request body and query param flows through a DTO class with `class-validator` decorators.
- Enable `ValidationPipe` globally with `whitelist: true, transform: true, forbidNonWhitelisted: true`.
- Response shapes are also DTOs (or interface types) — never return raw entities.

```ts
export class CreateUserDto {
  @IsEmail() email!: string;
  @IsString() @MinLength(8) password!: string;
}
```

## Status codes

- Default `2xx` (NestJS handles this) — be explicit with `@HttpCode()` only when overriding.
- Throw `HttpException` subclasses (`BadRequestException`, `NotFoundException`, `ForbiddenException`) — don't return error envelopes by hand.

## Exception filters

- One global exception filter that converts thrown errors into a consistent JSON shape:
  ```json
  { "status": "error", "statusCode": 400, "message": "...", "errors": [...] }
  ```

## Guards vs Interceptors vs Pipes

- **Pipes** — transform/validate input. Use for DTO validation, parameter parsing.
- **Guards** — authn/authz. Decide if a request proceeds.
- **Interceptors** — wrap the response (logging, caching, transform). Side effects around the handler.
- Don't put auth logic in interceptors. Don't validate input in guards.

## Versioning

- Use NestJS's `@Version()` or URL versioning (`@Controller({ path: 'users', version: '1' })`).
- Default version via `app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' })`.
