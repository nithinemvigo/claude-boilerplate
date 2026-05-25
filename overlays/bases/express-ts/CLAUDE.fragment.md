## {{STACK}}

- **Runtime:** Node.js v25 (see `.nvmrc`)
- **Framework:** Express ^4
- **Language:** TypeScript (strict, `NodeNext` modules)
- **Tests:** Jest + ts-jest + Supertest
- **Lint / format:** ESLint flat config + `typescript-eslint` + Prettier
- **Type:** HTTP REST API (no UI, no SSR)

## {{COMMANDS}}

### Dev loop
- `npm run dev` — `tsx watch src/index.ts` (hot reload, no build step)
- `npm test` — Jest with ts-jest
- `npm run test:coverage` — coverage report (target ≥ 80%)

### Quality
- `npm run lint` — ESLint (TypeScript-aware)
- `npm run lint:fix` — auto-fix what's safe
- `npm run format` — Prettier write
- `npm run format:check` — Prettier check only
- `npm run build` — `tsc -p tsconfig.json` (type-check + emit to `dist/`)
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
├── index.ts              ← Express app entrypoint
├── routes/               ← Route handlers grouped by resource
├── middleware/           ← Auth, validation, error handlers
├── services/             ← Business logic + external integrations
└── types/                ← Shared request/response shapes, domain entities
```

### What goes where

| Adding... | Lives in |
|---|---|
| A new resource endpoint | `src/routes/<resource>.ts` |
| Request middleware | `src/middleware/<name>.ts` |
| A service (DB, external API) | `src/services/<name>.ts` |
| A shared type (DTO, domain entity) | `src/types/<name>.ts` |
| A reusable utility | `src/utils/<name>.ts` |
| Tests | Co-located: `foo.ts` → `foo.test.ts` |

### Base-specific notes

- See `.claude/rules/api.md` for REST conventions, typed handler signatures, and response envelopes.
- See `.claude/rules/database.md` for parameterised queries, transactions, and migrations.
- See `.claude/rules/typescript.md` for strict-mode patterns — no `any`, prefer `unknown` + narrowing.
- Type handlers: `Request<Params, ResBody, ReqBody, ReqQuery>`. Define `ApiResponse<T>` once, use everywhere.
- `tsconfig.recommended.json` is provided as a starting point — copy values into your `tsconfig.json` (strict, `noUncheckedIndexedAccess`, path alias `@/*` → `src/*`).

## {{ANTIPATTERNS}}

- ❌ `any` anywhere in production code. Use `unknown` and narrow.
- ❌ `@ts-ignore` — fix the type. `@ts-expect-error` is acceptable only in tests with a comment.
- ❌ String-interpolated SQL — use parameterised queries.
- ❌ `process.env.X` cast to `string!` without checking — `process.env.X` is `string | undefined`. Validate at startup.
- ❌ `as` casts where a type guard would work. `as` silences the compiler; type guards make the runtime safe.
- ❌ Async route handlers without try/catch (or `express-async-errors`). Uncaught async hangs the request.
- ❌ Returning `err.stack` in responses — leaks server internals.
- ❌ `JSON.parse(input)` on user data without a schema validator. Use Zod or equivalent.
