## {{STACK}}

- **Runtime:** Node.js v20+ (see `.nvmrc`)
- **Framework:** Express ^4
- **Language:** JavaScript (CommonJS modules)
- **Database:** (set per project — Postgres / MongoDB / etc.)
- **Tests:** Jest + Supertest
- **Lint / format:** ESLint flat config + Prettier
- **Type:** HTTP REST API (no UI, no SSR)

## {{COMMANDS}}

### Dev loop
- `npm run dev` — start with `--watch` for hot reload
- `npm test` — Jest (add `-- --watch=false` for one-shot)
- `npm run test:coverage` — coverage report (target ≥ 80%)

### Quality
- `npm run lint` — ESLint
- `npm run lint:fix` — auto-fix what's safe
- `npm run format` — Prettier write
- `npm run format:check` — Prettier check only
- `npm run validate` — local gate (lint + format + test) = pre-commit hook minus AI steps

### Database
- `npm run db:migrate` — run pending migrations
- `npm run db:rollback` — roll back last migration
- `npm run db:seed` — seed dev data

### Preflight
- `npm run check-setup` — verify Node version, `claude` CLI, plugins, hook wiring, env

### Review
- `npm run review` — manual `/code-review` on the last commit

### Maintenance
- `npm run deps:audit` — production-only `npm audit`
- `npm run deps:outdated` — list outdated packages

## {{ARCHITECTURE}}

### Tree

```
src/
├── app.js                ← Express app setup (middleware + route registration). Exported for tests.
├── server.js             ← HTTP listener + DB connect + graceful shutdown. Entry point.
├── config/               ← Env loading, DB connection config
├── routes/               ← Route handlers grouped by resource (no logic)
├── controllers/          ← Request orchestration — calls services, shapes responses
├── services/             ← Business logic + external integrations
├── models/               ← DB schemas / data access
├── middlewares/          ← Auth, validation, error handlers, security
├── validation/           ← Joi/Zod schemas + validator middleware
└── utils/                ← Reusable helpers
```

### What goes where

| Adding... | Lives in |
|---|---|
| A new resource endpoint (`GET /api/v1/users`, etc.) | `src/routes/<resource>.routes.js` |
| Request handling logic for that endpoint | `src/controllers/<resource>.controller.js` |
| Business logic / external API calls | `src/services/<resource>.service.js` |
| DB schema or data access | `src/models/<resource>.model.js` |
| Validation schema for a request body | `src/validation/<resource>.validation.js` |
| Request middleware (auth, body parser, rate limit) | `src/middlewares/<name>.middleware.js` |
| A reusable utility | `src/utils/<name>.js` |
| Tests | Co-located: `foo.js` → `foo.test.js` |

### Base-specific notes

- See `.claude/rules/express.md` for folder structure, controller/route/middleware conventions.
- See `.claude/rules/api.md` for REST conventions (URL shapes, response envelope, status codes, CORS, rate limiting, versioning).
- See `.claude/rules/database.md` for parameterised queries, transactions, and migration discipline.
- See `.claude/rules/validation.md` for Joi/Zod schema patterns.
- See `.claude/rules/security.md` for auth, secrets, and hardening rules.
- See `.claude/rules/testing.md` for Jest + Supertest patterns.
- Async route handlers MUST use `express-async-handler` or try/catch. An uncaught async rejection hangs the request.
- `app.js` is exported for Supertest — `server.js` is the only place that calls `app.listen()`.

## {{ANTIPATTERNS}}

- ❌ `app.use(cors())` with no origin allowlist — never wildcards in production. Set `ALLOWED_ORIGINS` in env.
- ❌ String-interpolated SQL: `db.query(\`SELECT … WHERE id = ${id}\`)`. Use parameterised queries (`$1`, `?` placeholders).
- ❌ `process.env.SECRET || 'dev-fallback'` — the fallback IS the leak. Fail fast on missing secrets at startup.
- ❌ Returning `err.stack` in the response body — leaks file paths and server internals.
- ❌ Storing user input directly in path operations (`fs.readFile(req.query.path)`) — path traversal.
- ❌ Awaiting inside `forEach` — it doesn't await. Use `for..of` or `Promise.all`.
- ❌ Mutating the `req` or `res` object across files in non-obvious ways. If middleware mutates state, document it.
- ❌ DB queries inside controllers — always delegate to services/models.
- ❌ Defining routes inside `app.js` — register routers, don't inline handlers.
- ❌ `app.listen()` inside `app.js` — breaks Supertest. Keep it in `server.js`.
- ❌ Skipping `helmet`, `cors`, `express-rate-limit`, `compression` on `app.js` — these are mandatory baseline middleware.
- ❌ Hardcoded secrets, DB URIs, or JWT keys — everything via `config/config.js` reading from `.env`.