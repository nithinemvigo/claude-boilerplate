---
description: SQL safety, parameterised queries, transactions, migration discipline
globs:
  - "src/**/*.ts"
  - "**/migrations/**"
  - "**/db/**"
alwaysApply: false
---

# Database Rules

## Parameterised queries — always

```ts
// ✅ Good
await db.query('SELECT * FROM users WHERE id = $1', [id]);

// ❌ Bad — SQL injection
await db.query(`SELECT * FROM users WHERE id = ${id}`);
```

The pre-commit security review flags string-interpolated SQL.

## Transactions for multi-step writes
- Wrap order-create + inventory-decrement in a single transaction.
- Use the connection pool's transaction primitive — never start a transaction without committing or rolling back in every code path.

## Migrations are append-only
- Never edit a deployed migration. Write a new one to fix it.
- Migration filenames are timestamped, never renumbered.

## Connection pooling
- One pool per process. Reuse it.
- Size the pool to match your DB's max connections (rule of thumb: `min(20, db_max / num_processes)`).

## Don't fetch the world
- `LIMIT` on every query unless you've explicitly designed the result set.
- Select only the columns you use.

## Sensitive columns
- Don't `SELECT *` on tables with secret-bearing columns (password hashes, tokens). Be explicit about what you return.
