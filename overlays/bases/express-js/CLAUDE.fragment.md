## {{STACK}}

Node.js v25 (see `.nvmrc`) · Express · JavaScript (CommonJS).

## {{COMMANDS}}

```
npm run dev          # node --watch src/index.js
npm test             # jest
npm run test:coverage
npm run lint         # eslint .
npm run lint:fix
npm run format       # prettier --write .
npm run format:check
npm run validate     # lint + format:check + test
npm run review       # bash scripts/review.sh
npm run deps:audit
npm run deps:outdated
```

## {{ARCHITECTURE}}

- `src/index.js` — Express app entrypoint.
- `src/routes/` — Route handlers grouped by resource.
- `src/middleware/` — Custom middleware (auth, validation, error handlers).
- `src/services/` — Business logic and external integrations.
- `scripts/review.sh` — Manual code-review helper.
