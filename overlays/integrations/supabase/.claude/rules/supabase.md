---
description: Supabase rules — RLS, key separation, realtime cleanup, type generation
globs:
  - "**/lib/supabase/**"
  - "**/services/supabase*"
  - "supabase/**"
alwaysApply: false
---

# Supabase Rules

## Row-Level Security (RLS) is mandatory

- Every new table gets a policy. "It works because RLS is off in dev" is a bug, not a feature.
- The `anon` role must only see what the user is allowed to see. The `authenticated` role must only see what the logged-in user owns.
- Test policies with the Supabase SQL editor's "Run as role" feature before shipping.

## Key separation — never mix

- `NEXT_PUBLIC_SUPABASE_ANON_KEY` (or `VITE_*`) — safe in the browser.
- `SUPABASE_SERVICE_ROLE_KEY` — server-only. Bypasses RLS. **Never** import it in a Client Component or browser bundle.
- The pre-commit `/security-review` hook flags hardcoded service-role keys.

## Client initialization

- One client per environment (browser vs server).
- For Next.js, use `@supabase/ssr` with the cookies adapter — it refreshes tokens via middleware.
- For SPAs, use `@supabase/supabase-js` directly with the anon key.

## Realtime channels must unsubscribe

```ts
useEffect(() => {
  const channel = supabase.channel('todos').on('postgres_changes', ..., handler).subscribe();
  return () => { supabase.removeChannel(channel); };
}, []);
```

Forgetting cleanup leaks subscriptions across renders.

## Generated types are source of truth

- Run `supabase gen types typescript --project-id <ref> > src/types/supabase.ts` after every migration.
- Commit the generated file.
- Type queries with the generated `Database` type.

## Storage

- Public buckets are public — anyone with the URL reads. Treat as such.
- Signed URLs expire; verify TTL matches the use case (download link vs persistent image).

## Migrations

- Schema lives in `supabase/migrations/` as timestamped SQL files.
- Don't edit applied migrations — add a new one.
- Local dev: `npx supabase db reset` re-runs all migrations on a clean local DB.
