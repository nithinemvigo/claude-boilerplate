---
description: Prisma rules — schema as source of truth, migrations, singleton client, query selectivity
globs:
  - "prisma/**"
  - "**/lib/db*"
  - "**/services/db*"
alwaysApply: false
---

# Prisma Rules

## Schema is the source of truth

- Don't `ALTER TABLE` by hand. Change `prisma/schema.prisma`, then `prisma migrate dev`.
- The generated client is type-checked against the schema — out-of-band schema changes break types.

## Never edit applied migrations

- Migrations are append-only. To fix a deployed migration, write a new one.
- If you ran `prisma db push` in a dev env that already has migrations, your history diverges. See `core/.claude/rules/database.md` (or `overlays/bases/<base>/.claude/rules/database.md`) for recovery.

## Singleton PrismaClient

```ts
// src/lib/db.ts
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };
export const db = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = db;
```

One instance per process. In Next.js dev, attach to `globalThis` to survive HMR.

## Always select fields explicitly

```ts
// ✅ Good
const users = await db.user.findMany({ select: { id: true, email: true } });

// ❌ Bad — fetches everything, including sensitive columns
const users = await db.user.findMany();
```

Better perf and a hard wall against leaking columns you didn't realise were sensitive.

## Transactions for multi-step writes

```ts
await db.$transaction([
  db.order.create({ data: order }),
  db.inventory.update({ where: { sku }, data: { count: { decrement: 1 } } }),
]);
```

Cross-row writes without a transaction are a bug waiting to happen.

## Raw SQL only when necessary

- `$queryRaw` for the rare query Prisma's API can't express. Always use tagged templates for parameter binding: `db.$queryRaw\`SELECT * FROM users WHERE id = ${id}\``.
- Never concatenate user input into a raw SQL string.

## Connection pooling

- `DATABASE_URL` — pooled connection for runtime queries (PgBouncer, Supavisor, Neon).
- `DIRECT_URL` — direct connection for migrations.
- Supabase, Neon, and PlanetScale all require this split.

## Don't import Prisma in Client Components (Next.js)

The Next.js compiler will fail. Use Server Components, Server Actions, or Route Handlers.

## Seeding

- `prisma/seed.ts` + register in `package.json`'s `"prisma": { "seed": "tsx prisma/seed.ts" }`.
- Seeds are idempotent — use `upsert`, not `create`.
