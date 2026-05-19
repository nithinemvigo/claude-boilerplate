---
description: Tailwind rules — class organisation, theme tokens, responsive prefixes, when to apply
globs:
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.html"
  - "tailwind.config.*"
alwaysApply: false
---

# Tailwind Rules

## Class order matters

- Layout → sizing → spacing → typography → color → state.
- Use `prettier-plugin-tailwindcss` to auto-sort. The pre-commit Prettier check enforces this.
- Example: `flex items-center w-full px-4 py-2 text-sm text-slate-900 bg-white hover:bg-slate-50`.

## Extend the theme, don't override

```js
// ✅ Good — keeps Tailwind defaults
theme: { extend: { colors: { brand: '#0ea5e9' } } }

// ❌ Bad — loses Tailwind's color scale
theme: { colors: { brand: '#0ea5e9' } }
```

## Avoid arbitrary values

- `h-[37px]` is a code smell. If a value appears more than twice, promote it to the theme.
- `text-[14.5px]` is almost always wrong — use the type scale.

## Don't `@apply` reflexively

- If you're wrapping utilities in a custom class, the right answer is usually a component, not a class.
- `@apply` is for design-system primitives (`.btn`, `.card`) — not for "I don't like long className strings".

## Responsive prefixes go mobile-first

```tsx
<div className="w-full md:w-1/2 lg:w-1/3" />
```

Tailwind's defaults are mobile-first. Reading left-to-right matches that.

## Dark mode: use the `class` strategy

```js
// tailwind.config.js
darkMode: 'class',
```

Letting users toggle dark mode is better UX than tying it to system preference.

## Use the UI/UX Pro Max skill

The `ui-ux-pro-max` skill in `core/.claude/skills/` ships 96 palettes and 57 font pairings. Check it before inventing colors.
