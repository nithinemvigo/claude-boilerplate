---
description: RESTful API design rules — routing, response format, CORS, rate limiting, versioning
globs:
  - "src/**/*.ts"
  - "**/*.route.ts"
  - "**/*.controller.ts"
alwaysApply: false
---

# API Rules (TypeScript Express)

## Routing
- Use RESTful URL patterns: `GET /api/resources`, `POST /api/resources`, `GET /api/resources/:id`.
- Group related endpoints under a common prefix (`/api/users`, `/api/orders`).
- Use plural nouns for resource names, never verbs.

## Request handling
- Validate and sanitize request input before processing. Prefer a schema validator (Zod) over hand-rolled checks.
- Body size limit (~1MB) to prevent DoS.
- Reject unsupported `Content-Type` with `415`.
- Type your handlers: `Request<Params, ResBody, ReqBody, ReqQuery>`.

## Response format
- Always return JSON with consistent structure:
  ```json
  { "status": "success|error", "data": {}, "message": "" }
  ```
- Define a `ApiResponse<T>` type and use it on every handler.
- Status codes: `200`/`201`/`204` for success, `400`/`401`/`403`/`404`/`422`/`429` for client errors, `500` for server errors.

## CORS
- Never `Access-Control-Allow-Origin: *` in production.
- Whitelist origins via env var (`ALLOWED_ORIGINS`, comma-separated).

## Rate limiting
- Apply to all public-facing endpoints.
- Use `429 Too Many Requests` with `Retry-After`.

## Versioning
- Prefix routes with version: `/api/v1/resources`.
- Never break existing contracts without versioning.

## Async error handling
- Wrap async handlers in a `try/catch` or use an async-error middleware (`express-async-errors`).
- An unhandled async rejection in an Express handler hangs the request.
