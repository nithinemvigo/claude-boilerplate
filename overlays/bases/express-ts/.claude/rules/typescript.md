---
description: TypeScript rules — strict typing, interfaces, generics, type safety patterns
globs:
  - "**/*.ts"
  - "tsconfig*.json"
alwaysApply: false
---

# TypeScript Rules

## Strict config
- `strict: true` in `tsconfig.json`. No exceptions.
- Plus `noUncheckedIndexedAccess: true`.
- Never `@ts-ignore`. `@ts-expect-error` is acceptable in tests with a comment.

## Types vs interfaces
- `interface` for object shapes that may be extended or implemented by a class.
- `type` for unions, intersections, primitives, utility types.
- Never `any`. Use `unknown` then narrow.

```ts
// ✅ Good
function parse(input: unknown): string {
  if (typeof input !== 'string') throw new Error('Expected string');
  return input;
}
```

## Generics
- Descriptive names: `TEntity`, `TResponse`. Constrain when possible: `<T extends object>`.

## Null safety
- Prefer `?.` and `??` over manual null checks.
- Use `!` sparingly.

## Enums
- Prefer union types over string enums for public APIs: `type Status = 'active' | 'inactive'`.
- `const enum` only for pure compile-time constants.

## Path aliases
- Configure `paths` in `tsconfig.json` to avoid `../../..` imports.

## Public API
- Always type return values explicitly on exported functions.
