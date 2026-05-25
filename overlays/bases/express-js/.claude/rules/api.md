---
description: RESTful API design rules — routing, response format, CORS, rate limiting, versioning
globs:
  - "src/**/*.js"
  - "src/**/*.ts"
  - "**/*.route.js"
  - "**/*.route.ts"
  - "**/*.controller.js"
  - "**/*.controller.ts"
alwaysApply: false
---

# API Rules

## Routing
- Use RESTful URL patterns: `GET /api/v1/resources`, `POST /api/v1/resources`, `GET /api/v1/resources/:id`
- Group related endpoints under a common prefix (e.g., `/api/v1/users`, `/api/v1/orders`)
- Use plural nouns for resource names, never verbs in URLs (`/users` not `/getUsers`)
- Use lowercase, kebab-case for multi-word resources (`/user-profiles`)

## HTTP Methods
| Method | Endpoint        | Action             |
|--------|-----------------|--------------------|
| GET    | `/users`        | List all           |
| GET    | `/users/:id`    | Get one            |
| POST   | `/users`        | Create             |
| PUT    | `/users/:id`    | Update (full)      |
| PATCH  | `/users/:id`    | Update (partial)   |
| DELETE | `/users/:id`    | Delete             |

## Request Handling
- Always validate and sanitize request input before processing (see `validation.md`)
- Use a request body size limit (e.g., 1MB max) to prevent DoS: `express.json({ limit: '1mb' })`
- Parse `Content-Type` headers — reject unsupported types with `415`

## Response Format
- Always return JSON with a consistent envelope:
  ```json
  { "status": "success|error", "data": {}, "message": "" }
  ```
- Use appropriate HTTP status codes:
  - `200` OK, `201` Created, `204` No Content
  - `400` Bad Request, `401` Unauthorized, `403` Forbidden, `404` Not Found
  - `422` Validation Error, `429` Rate Limited
  - `500` Internal Server Error
- Set `Content-Type: application/json` on all responses

## CORS
- Never use `Access-Control-Allow-Origin: *` in production
- Whitelist specific origins via environment variable (`ALLOWED_ORIGINS`)
- Include proper `Access-Control-Allow-Methods` and `Access-Control-Allow-Headers`

## Rate Limiting
- Apply rate limiting to all public-facing endpoints (`express-rate-limit`)
- Use `429 Too Many Requests` with `Retry-After` header when limit exceeded
- Stricter limits on auth endpoints (login, register, password reset)

## Versioning
- Prefix API routes with version: `/api/v1/resources`
- Never break existing API contracts without bumping the version
- Mount versioned router in `app.js`: `app.use('/api/v1', require('./routes'))`