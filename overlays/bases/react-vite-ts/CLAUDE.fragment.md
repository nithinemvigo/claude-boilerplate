## {{STACK}}

Node.js v25 (see `.nvmrc`) · Vite · React 18+ · TypeScript (strict, bundler module resolution).

## {{COMMANDS}}

```
npm run dev          # vite (HMR dev server)
npm run build        # tsc -b && vite build
npm run preview      # vite preview (serves the built dist/)
npm test             # vitest (watch mode)
npm run test:coverage
npm run lint         # eslint .
npm run lint:fix
npm run format       # prettier --write .
npm run format:check
npm run validate     # lint + format + build + test
```

## {{ARCHITECTURE}}

- `src/main.tsx` — React entrypoint, root render.
- `src/App.tsx` — Top-level component.
- `src/components/` — Reusable UI components.
- `src/hooks/` — Custom React hooks (one hook per file).
- `src/lib/` — Framework-agnostic utilities and external client init (`supabase.ts`, `firebase.ts`).
- `src/routes/` or `src/pages/` — Route components (depending on router choice).
- `vite.config.ts` — Vite config.
- `tsconfig.json` — Strict mode, bundler resolution, path alias `@/*` → `src/*`.
