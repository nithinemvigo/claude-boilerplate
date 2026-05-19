---
description: Frontend component rules — composition, hooks discipline, accessibility, performance
globs:
  - "**/*.tsx"
  - "**/*.ts"
  - "app/**"
  - "components/**"
alwaysApply: false
---

# Frontend Rules (Next.js App Router)

## Server vs Client Components

- Default to Server Components. Add `"use client"` only when you need state, effects, or browser APIs.
- A Server Component can import a Client Component, but a Client Component can't render a Server Component below it (pass it as children instead).
- Don't reach for `"use client"` reflexively — most static-render leaf components don't need it.

## Component conventions

- One component per file. Co-locate styles, tests, and types.
- Props get a `Props` type, exported only if reused externally.
- Default exports for components; named exports for hooks, utilities, types.
- File naming: `Button.tsx`, `useAuth.ts`, `cn.ts`.

## Hooks discipline

- Hooks at the top of the function, never inside conditionals or loops.
- Custom hooks start with `use`.
- Cleanup in `useEffect` returns — always for subscriptions, listeners, timers.
- Don't put fetch logic in `useEffect` — use Server Components or `react-query`/SWR.

## Accessibility

- Every interactive element has an accessible name (text, `aria-label`, or `aria-labelledby`).
- Use semantic HTML (`<button>`, `<a>`, `<nav>`) before `<div>` + `role`.
- Form inputs have associated labels.
- Color contrast meets WCAG AA (4.5:1 for body text). The `ui-ux-pro-max` skill has palettes that pass.
- The `jsx-a11y` ESLint plugin runs on every commit.

## Performance

- `React.memo` only when profiling shows it helps. Premature memoization adds complexity for no gain.
- `useMemo`/`useCallback` only for stable refs needed by `memo` or deps arrays.
- Lazy-load heavy components with `dynamic()` and an explicit loading state.
- Images: always `next/image` with explicit `width`/`height` to prevent layout shift.

## State

- Local state stays local. Lift state only when shared.
- Server state (data from the API) is not "state" — fetch in Server Components or use a server-state library.
- URL is state too — use search params for filters, pagination, etc.
