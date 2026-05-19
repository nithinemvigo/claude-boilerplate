---
description: TypeScript rules — strict typing, decorators, NestJS-aware patterns
globs:
  - "**/*.ts"
  - "tsconfig*.json"
alwaysApply: false
---

# TypeScript Rules

## Strict config

- `strict: true` + `noUncheckedIndexedAccess: true`.
- NestJS requires `experimentalDecorators: true` and `emitDecoratorMetadata: true` — these are non-negotiable.
- Never `@ts-ignore`. `@ts-expect-error` is acceptable in tests with a comment.

## Decorator-heavy code

- Class fields used as decorators' targets need `!` (definite assignment) or a default value. Don't use `?` if the validator says it's required.
- The dependency-injection container relies on parameter types — don't replace them with `any`.

## Types vs interfaces

- `interface` for object shapes that may be extended or implemented by a class.
- `type` for unions, intersections, primitives, utility types.

## Never `any`

- Use `unknown` for genuinely-unknown inputs, then narrow.
- `as unknown as X` is a smell — fix the underlying type or write a type guard.

## Null safety

- `?.` and `??` over manual null checks.
- Avoid non-null assertion `!` outside decorator-required fields.

## Public APIs

- Always type return values explicitly on exported services and controllers.
- Use `Readonly<T>` for objects that shouldn't mutate.

## Path aliases

- Configure `paths` in `tsconfig.json` (`@/*` → `src/*`). Avoid `../../..` imports.
