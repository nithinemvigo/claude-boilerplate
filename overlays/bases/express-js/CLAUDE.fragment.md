## {{STACK}}

- **Runtime:** Node.js v25 (see `.nvmrc`)
- **Framework:** Express ^4
- **Language:** JavaScript (CommonJS modules)
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
├── index.js              ← Express app entrypoint (mounts routes + middleware, calls app.listen)
├── routes/               ← Route handlers grouped by resource
├── middleware/           ← Auth, validation, error handlers
└── services/             ← Business logic + external integrations
```

### What goes where

| Adding... | Lives in |
|---|---|
| A new resource endpoint (`GET /api/users`, etc.) | `src/routes/<resource>.js` |
| Request middleware (auth, body parser, rate limit) | `src/middleware/<name>.js` |
| A service that talks to a DB / external API | `src/services/<name>.js` |
| A reusable utility | `src/utils/<name>.js` (create the folder if needed) |
| Tests | Co-located: `foo.js` → `foo.test.js` |

### Base-specific notes

- See `.claude/rules/api.md` for REST conventions (URL shapes, response envelope, status codes, CORS, rate limiting, versioning).
- See `.claude/rules/database.md` for parameterised queries, transactions, and migration discipline.
- Async route handlers must use try/catch (or `express-async-errors`). An uncaught async rejection hangs the request.

## {{ANTIPATTERNS}}

- ❌ `app.use(cors())` with no origin allowlist — never wildcards in production. Set `ALLOWED_ORIGINS` in env.
- ❌ String-interpolated SQL: `db.query(\`SELECT … WHERE id = ${id}\`)`. Use parameterised queries (`$1`, `?` placeholders).
- ❌ `process.env.SECRET || 'dev-fallback'` — the fallback IS the leak. Fail fast on missing secrets at startup.
- ❌ Returning `err.stack` in the response body — leaks file paths and server internals.
- ❌ Storing user input directly in path operations (`fs.readFile(req.query.path)`) — path traversal.
- ❌ Awaiting inside `forEach` — it doesn't await. Use `for..of` or `Promise.all`.
- ❌ Mutating the `req` or `res` object across files in non-obvious ways. If middleware mutates state, document it.
