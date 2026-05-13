# API Rules

## Routing
- Use RESTful URL patterns: `GET /api/resources`, `POST /api/resources`, `GET /api/resources/:id`
- Group related endpoints under a common prefix (e.g., `/api/users`, `/api/orders`)
- Use plural nouns for resource names, never verbs in URLs

## Request Handling
- Always validate and sanitize request input before processing
- Use a request body size limit (e.g., 1MB max) to prevent DoS
- Parse `Content-Type` headers — reject unsupported types with `415`

## Response Format
- Always return JSON with consistent structure:
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
- Whitelist specific origins via environment variable
- Include proper `Access-Control-Allow-Methods` and `Access-Control-Allow-Headers`

## Rate Limiting
- Apply rate limiting to all public-facing endpoints
- Use `429 Too Many Requests` with `Retry-After` header when limit exceeded

## Versioning
- Prefix API routes with version: `/api/v1/resources`
- Never break existing API contracts without versioning
