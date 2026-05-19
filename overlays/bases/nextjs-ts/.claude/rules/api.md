---
description: API rules for Next.js Route Handlers — validation, errors, status codes
globs:
  - "app/api/**"
  - "app/**/route.ts"
alwaysApply: false
---

# API Rules (Next.js Route Handlers)

## Handler signatures

- Export named functions matching HTTP methods: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`.
- Use Web `Request` / `NextRequest` and `Response` / `NextResponse`.

```ts
export async function GET(req: NextRequest) {
  const data = await load();
  return NextResponse.json({ status: 'success', data });
}
```

## Validate input

- Body parsing: `await req.json()` then validate. Don't trust the shape.
- Query params: `req.nextUrl.searchParams.get('x')` — always nullable; narrow.
- Use a schema validator (Zod) for anything beyond trivial cases.

## Response format

- Consistent envelope:
  ```json
  { "status": "success|error", "data": {...}, "message": "..." }
  ```
- Status codes via `NextResponse.json(body, { status: 400 })`. Defaults to 200.
- Set `Content-Type: application/json` (NextResponse.json does this automatically).

## Errors

- Don't expose stack traces. Log the real error server-side, return a sanitised message.
- 4xx for client errors, 5xx for server errors.

## Authn / authz

- Authenticate at the top of the handler — don't trust the route's existence as authorization.
- Reuse a `requireAuth(req)` helper that returns the user or throws an `UnauthorizedError`.

## Idempotency

- `GET` and `HEAD` must be safe — no side effects.
- `PUT` and `DELETE` should be idempotent — repeating the request gives the same result.
- `POST` is non-idempotent; clients can retry on network failure and get duplicates. Build idempotency keys into critical mutations (payments, signup).
