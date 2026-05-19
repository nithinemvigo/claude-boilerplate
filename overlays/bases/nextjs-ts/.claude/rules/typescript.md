---
description: TypeScript rules for Next.js — strict, RSC-aware, path aliases
globs:
  - "**/*.ts"
  - "**/*.tsx"
  - "tsconfig*.json"
alwaysApply: false
---

# TypeScript Rules (Next.js)

## Strict config

- `strict: true` + `noUncheckedIndexedAccess: true`.
- `moduleResolution: "bundler"` for Next's app dir.
- Never `@ts-ignore`. `@ts-expect-error` is acceptable in tests with a comment.

## Types vs interfaces

- `interface` for object shapes that may be extended or implemented by a class.
- `type` for unions, intersections, primitives, utility types.

## Never `any`

- Use `unknown` then narrow. Type guards over assertions.

## Server vs Client types

- Server-only types stay in `app/**` files. Client-only types live in components marked `"use client"`.
- Don't import a Node-only library type into a Client Component — the type can leak Node typings the bundler can't resolve.

## Path aliases

- `@/*` → `./*` (Next.js default).

## Public API

- Always type return values explicitly on exported functions.

## Form data

- `formData.get(name)` returns `FormDataEntryValue | null`. Narrow before use:
  ```ts
  const email = formData.get('email');
  if (typeof email !== 'string') throw new Error('Invalid email');
  ```
