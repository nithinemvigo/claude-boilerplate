Tailwind CSS is the styling layer. Config in `tailwind.config.js` (or `tailwind.config.ts`). Global imports in `src/styles/globals.css` (Vite) or `app/globals.css` (Next.js). Class sorting is enforced by `prettier-plugin-tailwindcss` via the pre-commit Prettier check.

Design tokens (colors, spacing, type scale, fonts) live in the theme config — see `.claude/rules/tailwind.md` for the conventions.
