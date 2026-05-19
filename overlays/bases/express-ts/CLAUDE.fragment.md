## {{STACK}}

Node.js v25 (see `.nvmrc`) · Express · TypeScript (strict, ES Modules / NodeNext).

## {{COMMANDS}}

```
npm run dev          # tsx watch src/index.ts
npm run build        # tsc
npm start            # node dist/index.js
npm test             # jest (ts-jest)
npm run test:coverage
npm run lint         # eslint .
npm run lint:fix
npm run format       # prettier --write .
npm run format:check
npm run validate     # lint + format + build + test
```

## {{ARCHITECTURE}}

- `src/index.ts` — Express app entrypoint.
- `src/routes/` — Route handlers grouped by resource.
- `src/middleware/` — Custom middleware (auth, validation, error).
- `src/services/` — Business logic and external integrations.
- `src/types/` — Shared TypeScript types (request/response shapes, domain entities).
- `tsconfig.json` — Strict mode, `noUncheckedIndexedAccess`, path alias `@/*` → `src/*`.
