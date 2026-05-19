---
description: TypeScript rules — strict typing, interfaces, generics, type safety patterns
globs:
  - "**/*.ts"
  - "**/*.tsx"
  - "tsconfig*.json"
alwaysApply: false
---

# TypeScript Rules

## Strict Config
- Always enable `strict: true` in `tsconfig.json` — no exceptions
- Use `noImplicitAny`, `strictNullChecks`, `noUncheckedIndexedAccess`
- Never use `@ts-ignore` — fix the underlying type issue instead
- `@ts-expect-error` is acceptable only in test files with a comment explaining why

## Types vs Interfaces
- Use `interface` for object shapes that may be extended or implemented by a class
- Use `type` for unions, intersections, primitives, and utility types
- Never use `any` — use `unknown` when the type is genuinely unknown, then narrow it

```typescript
// ✅ Good
function parse(input: unknown): string {
  if (typeof input !== 'string') throw new Error('Expected string');
  return input;
}

// ❌ Bad
function parse(input: any): string { return input; }
```

## Generics
- Use descriptive names: `TEntity`, `TResponse`, `TConfig` — not just `T`
- Constrain generics when possible: `<T extends object>` not `<T>`

## Null Safety
- Prefer optional chaining `?.` and nullish coalescing `??` over manual null checks
- Use non-null assertion `!` sparingly — only when you are certain the value exists

## Enums
- Prefer `const enum` for pure compile-time constants
- Prefer union types over string enums for public APIs: `type Status = 'active' | 'inactive'`

## Path Aliases
- Configure `paths` in `tsconfig.json` for clean imports — avoid deep relative paths (`../../..`)
- Example: `@/services/fb` instead of `../../services/fb`

## Exports
- Always type function return values explicitly for public API functions
- Use barrel exports (`index.ts`) for clean module boundaries
