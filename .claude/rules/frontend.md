---
description: Frontend rules — React/Vue/Next.js component patterns, state management, accessibility, performance
globs:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
  - "src/app/**"
  - "src/pages/**"
  - "src/components/**"
alwaysApply: false
---

# Frontend Rules

## Component Design
- One component per file — filename matches component name (PascalCase)
- Keep components under 150 lines — extract sub-components if exceeding
- Separate concerns: presentational components contain no business logic
- Props must be typed explicitly — no implicit `any` for component props

```typescript
// ✅ Good
interface ButtonProps {
  label: string;
  onClick: () => void;
  variant?: 'primary' | 'secondary';
  disabled?: boolean;
}
```

## State Management
- Use local state (`useState`) before reaching for global state
- Lift state to the nearest common ancestor — no prop drilling beyond 2 levels
- Context is for global UI state (theme, auth) — not for server data
- Server state (API data): use a data-fetching library (SWR, React Query) — never raw `useEffect` + `useState` for fetching

## Hooks
- Custom hooks start with `use` and live in `src/hooks/`
- Each hook has one responsibility
- Never call hooks conditionally

## Performance
- Memoize expensive computations with `useMemo` — not `useCallback` for everything
- `useCallback` only when a callback is passed as a prop to a memoized child
- Lazy-load routes and heavy components with `React.lazy` / dynamic imports
- Images must have explicit `width` and `height` to prevent layout shift

## Accessibility
- All interactive elements must be keyboard-navigable
- Images require meaningful `alt` text — empty `alt=""` only for decorative images
- Use semantic HTML elements (`<button>`, `<nav>`, `<main>`, `<article>`)
- Form inputs must have associated `<label>` elements

## Styling
- No inline styles except for dynamic values that cannot be expressed in CSS
- CSS class names use kebab-case; component-specific styles scoped to the component
- CSS custom properties (variables) for theme values — no hardcoded colors

## API Calls from Frontend
- Never expose API secrets or service account keys in frontend code
- All API calls go through `src/services/` — no raw `fetch`/`axios` in components
- Handle loading, error, and empty states explicitly in every data-dependent component
