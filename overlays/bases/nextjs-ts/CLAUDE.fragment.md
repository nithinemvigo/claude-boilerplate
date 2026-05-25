## {{STACK}}

- **Runtime:** Node.js v25 (see `.nvmrc`)
- **Framework:** Next.js ^15 (App Router — RSC, Server Actions, Route Handlers)
- **Language:** TypeScript (strict, `moduleResolution: bundler`)
- **Tests:** Vitest + `@testing-library/react` + jsdom
- **Lint:** `next lint` (extends `next/core-web-vitals`) + Prettier
- **Type:** Full-stack React app (SSR, server components, server actions, API routes)

## {{COMMANDS}}

### Dev loop
- `npm run dev` — Next.js dev server with HMR
- `npm test` — Vitest watch mode
- `npm run test:coverage` — coverage report

### Quality
- `npm run lint` — `next lint` (Next.js's own runner)
- `npm run lint:fix` — auto-fix what's safe
- `npm run format` — Prettier write
- `npm run format:check` — Prettier check only
- `npm run build` — `next build` (type-check + production bundle)
- `npm start` — serve the production build locally
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
app/
├── layout.tsx               ← Root layout (Server Component)
├── page.tsx                 ← Root page (Server Component)
├── <route>/
│   ├── page.tsx             ← Route page
│   ├── layout.tsx           ← Optional nested layout
│   └── loading.tsx          ← Optional Suspense fallback
└── api/
    └── <route>/route.ts     ← Route Handler (REST endpoint)
components/                  ← Reusable components (Server by default; mark "use client" when needed)
lib/                         ← Utilities + external client init (db, supabase, firebase)
middleware.ts                ← Runs on the Edge runtime (auth, redirects, headers)
public/                      ← Static assets served at root
```

### What goes where

| Adding... | Lives in |
|---|---|
| A new page | `app/<route>/page.tsx` |
| A nested layout | `app/<route>/layout.tsx` |
| A REST endpoint | `app/api/<route>/route.ts` (exports `GET`, `POST`, ...) |
| A Server Action | A function with `"use server"` directive, often in `app/<route>/actions.ts` |
| A reusable UI component | `components/<Name>.tsx` |
| A custom hook | Only inside a Client Component — `lib/hooks/use<Name>.ts` |
| External client init (Supabase, Prisma, Firebase) | `lib/<client-name>.ts` |
| Auth / middleware logic | `middleware.ts` (Edge runtime — beware Node-only deps) |
| Tests | Co-located: `Button.tsx` → `Button.test.tsx` |

### Base-specific notes

- See `.claude/rules/frontend.md` for component conventions, accessibility.
- See `.claude/rules/typescript.md` for strict TS patterns.
- See `.claude/rules/nextjs-conventions.md` for Server vs Client Components, data fetching/caching, Server Actions vs Route Handlers, Edge runtime gotchas.
- See `.claude/rules/api.md` for Route Handler patterns (validation, error envelopes, status codes).
- `next.config.js` and `next-env.d.ts` are managed by Next — don't edit `next-env.d.ts`.
- `tsconfig.recommended.json` is a starting point; merge into Next's scaffolded `tsconfig.json`.

## {{ANTIPATTERNS}}

- ❌ Importing a Node-only library (`prisma`, `firebase-admin`, `fs`, `path`) into a Client Component. Compiler fails at build. Keep Node imports in Server Components, Server Actions, or Route Handlers.
- ❌ `"use client"` at the top of every component "to avoid errors". Server-by-default is faster and ships zero JS for that tree.
- ❌ Naive `fetch('/api/me')` in a Server Component — Next caches `fetch` forever by default. Use `{ next: { revalidate: N } }` or `{ cache: 'no-store' }` deliberately.
- ❌ `NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY` — anything `NEXT_PUBLIC_*` ends up in the browser bundle. Service-role keys are server-only.
- ❌ Server Actions that don't validate their inputs. Server Actions are public endpoints — treat them like API routes.
- ❌ Returning class instances or functions from Server Actions. The boundary only crosses serialisable values.
- ❌ `useState` in a Server Component. Server Components don't have state — split out a Client Component child.
- ❌ Mutations in `GET` handlers. `GET` must be safe — use `POST`/`PUT`/`DELETE`/`PATCH`.
- ❌ `<a href>` for internal navigation. Use `<Link>` from `next/link` — gets you client-side routing and prefetch.
- ❌ Raw `<img>` tags. Use `<Image>` from `next/image` with explicit width/height to avoid layout shift.
- ❌ Editing `next-env.d.ts` — Next regenerates it.
