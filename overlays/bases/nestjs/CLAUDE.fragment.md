## {{STACK}}

Node.js v25 (see `.nvmrc`) · NestJS · TypeScript with decorators (`experimentalDecorators`, `emitDecoratorMetadata`).

## {{COMMANDS}}

```
npm run dev          # nest start --watch
npm run build        # nest build
npm start            # node dist/main.js
npm test             # jest
npm run test:e2e     # jest e2e config
npm run test:coverage
npm run lint         # eslint .
npm run lint:fix
npm run format       # prettier --write .
npm run format:check
npm run validate     # lint + format + build + test
```

## {{ARCHITECTURE}}

- `src/main.ts` — Application bootstrap, global pipes/filters/interceptors.
- `src/app.module.ts` — Root module composing feature modules.
- `src/modules/<feature>/` — One folder per bounded context, each with its own `*.module.ts`, `*.controller.ts`, `*.service.ts`, and `dto/`.
- `src/common/` — Cross-cutting filters, guards, interceptors, pipes.
- `test/` — E2E tests; unit tests live alongside source as `*.spec.ts`.
- `tsconfig.json` — Strict mode + decorator metadata. Path alias `@/*` → `src/*`.
