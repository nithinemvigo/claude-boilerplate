---
description: Security rules — auth, secrets, headers, cookies, common attack mitigation
globs:
  - "src/**/*.js"
  - "src/**/*.ts"
alwaysApply: true
---

# Security Rules

## Secrets & Config
- ALL secrets via env vars — never hardcoded, never committed
- Fail fast on missing required secrets at startup (do NOT fallback to dev defaults)
- `.env` in `.gitignore`; commit `.env.example` only
- Never log secrets, tokens, passwords, or full cookies

## HTTP Headers
- Use `helmet()` on every app — sets CSP, HSTS, X-Frame-Options, etc.
- Set `Content-Type: application/json` on all JSON responses
- Never echo `Server` or framework version headers

## CORS
- Whitelist origins via `ALLOWED_ORIGINS` env — comma-separated list
- NEVER `Access-Control-Allow-Origin: *` in production
- Set `credentials: true` only when actually using cookies

## Authentication
- Use JWT with short expiry (≤ 1h) + refresh tokens, OR session cookies
- Hash passwords with `bcrypt` (cost ≥ 12) or `argon2` — never MD5/SHA1
- Verify tokens in middleware — never inside controllers
- Reject missing/invalid tokens with `401`; lack of permission with `403`

## Cookies
- ALWAYS: `httpOnly: true`, `secure: NODE_ENV === 'production'`, `sameSite: 'Strict'`
- Set `maxAge` explicitly — no infinite cookies

## Rate Limiting
- Apply `express-rate-limit` to all public routes
- Stricter limits on auth endpoints (login, register, password reset)
- Return `429` with `Retry-After` header when exceeded

## Injection Prevention
- ALWAYS parameterized queries — never string-interpolate user input into SQL/Mongo queries
- Sanitize user input rendered in HTML responses
- Never pass user input to `fs.readFile`, `child_process.exec`, or `eval`
- Validate file paths against a whitelist — block `..` and absolute paths

## Error Responses
- NEVER return `err.stack` in production responses — leaks file paths and internals
- Return generic messages for `500` errors; log details server-side only

## Dependencies
- Run `npm audit` regularly; fix high/critical issues before merging
- Pin major versions; review transitive dep changes