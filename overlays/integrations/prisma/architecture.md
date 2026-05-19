Prisma is the ORM. Schema in `prisma/schema.prisma`. Migrations in `prisma/migrations/` — never edit applied migrations, add new ones. Singleton client in `src/lib/db.ts` (or `app/lib/db.ts` for Next.js App Router). See `.claude/rules/prisma.md` for query conventions, transaction patterns, and the singleton template.

`DATABASE_URL` is the runtime (pooled) connection; `DIRECT_URL` is for migrations and bypasses the pooler.
