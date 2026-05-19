---
description: Next.js App Router conventions — RSC, Server Actions, Route Handlers, caching
globs:
  - "app/**"
  - "next.config.*"
  - "middleware.ts"
alwaysApply: false
---

# Next.js App Router Conventions

## Server Components vs Client Components

- Default: Server Component. Adds zero JS to the bundle.
- `"use client"` only for: state, effects, browser APIs, event handlers, third-party Client-only components.
- Server Components can fetch directly: `const data = await db.user.findMany()`.
- Client Components can't be async functions.

## Data fetching

- Server Components: just `await` — Next caches `fetch()` by default.
- `fetch(url, { next: { revalidate: 60 } })` — ISR-style revalidation.
- `fetch(url, { cache: 'no-store' })` — never cache.
- `fetch(url, { next: { tags: ['user'] } })` — tag for `revalidateTag()`.
- Don't mix React Query with Server Components fetches — pick one source of truth per surface.

## Server Actions

- `"use server"` at the top of a file or function declares it as a Server Action.
- Use for mutations (form submit, button click that writes data).
- Always validate input — Server Actions are public endpoints.
- Return serialisable values (POJOs, primitives) — class instances and functions don't cross the boundary.

## Route Handlers

- `app/api/<route>/route.ts` exports `GET`, `POST`, etc.
- Use Web `Request`/`Response` APIs, not Express idioms.
- For REST CRUD, prefer Route Handlers; for form mutations, prefer Server Actions.

## Middleware

- One `middleware.ts` at the project root.
- Runs on the Edge runtime by default — Node-only deps (Prisma, Firebase Admin) won't work there without the Data Proxy.
- Use the `matcher` config to scope middleware to specific routes.

## Layouts

- Layouts are Server Components by default.
- A layout that needs state must split: keep the layout server-side, render a Client Component child for the interactive parts.

## Environment variables

- `NEXT_PUBLIC_*` reaches the browser. Everything else stays server-side.
- Never prefix a secret with `NEXT_PUBLIC_` "just in case" — once exposed, it's exposed in every build forever.

## Caching gotchas

- The `fetch` cache is per request and per build. A naive `fetch('/api/me')` in a Server Component is cached forever.
- `revalidatePath()` and `revalidateTag()` invalidate from Server Actions.
