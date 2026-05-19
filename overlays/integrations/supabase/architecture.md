Supabase is the data + auth + storage layer. Client init lives in `src/lib/supabase/` (or `app/lib/supabase/` for Next.js App Router):

- `client.ts` — browser client (anon key only)
- `server.ts` — server client with cookies adapter (Next.js: `@supabase/ssr`)
- `service.ts` — service-role client, **server-only**, used for privileged operations

**RLS policies are the source of truth for authorization.** Application code assumes RLS is on. See `.claude/rules/supabase.md`.

Migrations live in `supabase/migrations/`. Generated types in `src/types/supabase.ts` (regenerate after every migration with `supabase gen types typescript`).
