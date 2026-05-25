## {{STACK}}

- **Runtime:** Node.js v25 (see `.nvmrc`)
- **Bundler:** Vite ^6
- **Framework:** React 18+
- **Language:** TypeScript (strict, `moduleResolution: bundler`)
- **Tests:** Vitest + `@testing-library/react` + jsdom
- **Lint / format:** ESLint flat config + `typescript-eslint` + `react-hooks` + `jsx-a11y` + Prettier
- **Type:** Single-page application (no SSR, no Node runtime)

## {{COMMANDS}}

### Dev loop
- `npm run dev` — Vite dev server with HMR
- `npm test` — Vitest watch mode
- `npm run test:coverage` — coverage report (target ≥ 80%; client components can need a lower target)

### Quality
- `npm run lint` — ESLint
- `npm run lint:fix` — auto-fix what's safe
- `npm run format` — Prettier write
- `npm run format:check` — Prettier check only
- `npm run build` — `tsc -b && vite build` — type-check + production bundle
- `npm run preview` — serve the production bundle locally
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
├── main.tsx              ← Entry point (mount React onto #root)
├── App.tsx               ← Top-level shell
├── components/           ← Reusable UI components (one per file)
├── hooks/                ← Custom React hooks (one per file, use* prefix)
├── lib/                  ← Framework-agnostic utilities + external client init
├── routes/ | pages/      ← Route components (depending on router choice)
├── styles/               ← Global styles / theme files
└── types/                ← Shared TS types
```

### What goes where

| Adding... | Lives in |
|---|---|
| A reusable UI component | `src/components/<Name>.tsx` (one component per file) |
| A custom hook | `src/hooks/use<Name>.ts` |
| A route / page | `src/routes/<Name>.tsx` or `src/pages/<Name>.tsx` |
| A non-React utility (formatting, date math, fetcher) | `src/lib/<name>.ts` |
| External client init (Supabase, Firebase) | `src/lib/<client-name>.ts` |
| A shared TS type used in multiple places | `src/types/<name>.ts` |
| Tests | Co-located: `Button.tsx` → `Button.test.tsx` |

### Base-specific notes

- See `.claude/rules/frontend.md` for component conventions, hooks discipline, accessibility, performance.
- See `.claude/rules/typescript.md` for strict TS patterns — discriminated unions over enums, prop typing, no `any`.
- The `ui-ux-pro-max` skill in `.claude/skills/` auto-triggers on UI work — 96 palettes, 57 font pairings, 99 UX guidelines.
- ESLint runs `jsx-a11y` — accessibility is enforced on every commit.
- `tsconfig.recommended.json` is a starting point; merge values into the Vite scaffold's `tsconfig.app.json`.

## {{ANTIPATTERNS}}

- ❌ Importing a Node-only library (`fs`, `path`, `prisma`, `firebase-admin`) into a component — Vite will fail at build time. Server work belongs in a separate backend.
- ❌ Hooks inside conditionals, loops, or after early returns. React requires stable hook order — see `react-hooks/rules-of-hooks`.
- ❌ Missing cleanup in `useEffect` for subscriptions / listeners / timers. Returns from effects unsubscribe; without them, you leak.
- ❌ Reaching into `document.querySelector` to mutate state. Use refs (`useRef`) and React state.
- ❌ `React.memo` / `useMemo` / `useCallback` sprinkled everywhere "for performance". Profile first; premature memoization is just complexity.
- ❌ Storing server-fetched data in `useState` and refetching on every mount. Use a server-state library (TanStack Query, SWR) or lift to a route loader.
- ❌ `<div>` + `onClick` instead of `<button>`. Loses keyboard accessibility — `jsx-a11y` will flag it.
- ❌ Inline `style={{...}}` for anything not truly dynamic. CSS / Tailwind / CSS modules scale better.
- ❌ Hardcoded API URLs. Use `import.meta.env.VITE_*` (Vite's env prefix).
