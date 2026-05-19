## {{STACK}}

Node.js v25 (see `.nvmrc`) · Next.js (App Router) · React 18+ · TypeScript (strict, `moduleResolution: bundler`).

## {{COMMANDS}}

```
npm run dev          # next dev
npm run build        # next build
npm start            # next start
npm run lint         # next lint (Next.js's own ESLint runner)
npm run lint:fix
npm run format       # prettier --write .
npm run format:check
npm test             # vitest
npm run test:coverage
npm run validate     # lint + format + build + test
```

## {{ARCHITECTURE}}

- `app/` — App Router root.
  - `app/layout.tsx` — Root layout (Server Component).
  - `app/page.tsx` — Root page.
  - `app/<route>/page.tsx` — Route pages.
  - `app/api/<route>/route.ts` — Route Handlers (REST endpoints).
- `components/` — Reusable components. Server by default; mark `"use client"` only where needed.
- `lib/` — Framework-agnostic utilities and external client init (`supabase.ts`, `db.ts`, `firebase.ts`).
- `middleware.ts` — Runs on the Edge runtime (auth, redirects, headers).
- `public/` — Static assets served at the root.
- `tsconfig.json` — Strict mode, bundler module resolution, path alias `@/*` → `./*`.
