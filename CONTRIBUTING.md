# Contributing to Claude Boilerplate

Thanks for wanting to extend the boilerplate. This guide covers the three common changes: adding a **base**, an **integration**, or a **preset**. If you're doing something else — fixing core, tweaking apply.sh, updating docs — read [`CLAUDE.md`](CLAUDE.md) at the repo root first; it has the "rules for Claude editing this repo" that apply equally to humans.

> **TL;DR of the design constraints**
>
> - `core/` is stack-agnostic. Anything that mentions a specific framework belongs in a base, not core.
> - Bases own framework files (eslint, tsconfig, scripts) and may override core defaults.
> - Integrations are **additive only**. They never overwrite a file from `core/` or the base. `apply.sh` aborts with exit code 3 if they try.
> - Every change must be verifiable with `bash scripts/apply.sh --dry`.

---

## Adding a new base

A base is one framework's starting point (Express, NestJS, React+Vite, etc.). Pick a name (kebab-case, no dots), then:

### 1. Create the folder

```bash
mkdir -p overlays/bases/<base>/.claude/rules
```

### 2. Add framework-specific rule files

In `overlays/bases/<base>/.claude/rules/`, drop the rules that only apply to this framework. Naming conventions:

- `frontend.md` — for React-, Vue-, Svelte-flavored bases
- `api.md` — for any base that exposes HTTP endpoints
- `database.md` — if the base typically talks to a SQL store
- `typescript.md` — every TS base
- `<framework>-conventions.md` — framework-specific patterns (e.g. `nestjs-conventions.md`, `nextjs-conventions.md`)

Each rule file uses YAML frontmatter:

```markdown
---
description: One-line summary used in editor pickers
globs:
  - "src/**/*.ts"
  - "app/**/*.tsx"
alwaysApply: false
---

# <Name> Rules

## <Topic>
- Concrete rule, with rationale where helpful
```

Aim for 50–200 lines per file. Less reads thin; more becomes a textbook.

### 3. Add the build config files

| File | Purpose |
|---|---|
| `eslint.config.js` | Flat ESLint config tailored to the framework (TS-eslint, react-hooks, jsx-a11y, etc.) |
| `tsconfig.recommended.json` | TS bases only — `strict: true`, `noUncheckedIndexedAccess`, path aliases |
| `.nvmrc` | Node version (currently `25` for v1 bases) |

### 4. Add `package.scripts.json`

Scripts + devDeps that get deep-merged into the target's `package.json`. Required scripts: `lint`, `lint:fix`, `format`, `format:check`, `test`, `validate`. Strongly recommended: `build`, `dev`, `start`, `test:coverage`, `deps:audit`, `deps:outdated`.

```json
{
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "dev": "tsx watch src/index.ts",
    "test": "jest",
    "validate": "npm run lint && npm run format:check && npm run build && npm test"
  },
  "devDependencies": {
    "typescript": "^5.7.2",
    "typescript-eslint": "^8.18.0"
  }
}
```

### 5. Add `CLAUDE.fragment.md`

The fragment fills the **four** placeholders in `core/CLAUDE.template.md`. Each section is headed by `## {{KEY}}`:

```markdown
## {{STACK}}

- **Runtime:** Node.js v25
- **Framework:** <Framework>
- **Language:** TypeScript (strict)
- **Tests:** Jest / Vitest
- **Lint / format:** ESLint flat config + Prettier
- **Type:** <e.g. HTTP REST API, SPA, fullstack>

## {{COMMANDS}}

### Dev loop
- `npm run dev` — ...
- `npm test` — ...

### Quality
- `npm run lint` / `lint:fix` / `format` / `validate`

(group your scripts by purpose — see existing fragments)

## {{ARCHITECTURE}}

### Tree
```
src/
├── ...
```

### What goes where

| Adding... | Lives in |
|---|---|
| ...

### Base-specific notes
- See `.claude/rules/<file>.md` for ...

## {{ANTIPATTERNS}}

- ❌ <Concrete anti-pattern with rationale>
- ❌ <Another one>
```

Keep it terse — Claude reads this on every project apply, so size matters. The `{{ANTIPATTERNS}}` section is your chance to encode "looks right but is wrong" patterns specific to this stack.

### 6. Add `compatible-integrations.txt`

One integration name per line. `apply.sh` rejects any integration not in this list.

```
supabase
firebase
prisma
```

### 7. Update `scripts/apply.sh`

Add a case for your new base in `compat_for()`:

```bash
compat_for() {
  case "$1" in
    express-js)     echo "supabase firebase prisma trpc zod" ;;
    your-base)      echo "<allowed integrations>" ;;   # ← add this
    *)              echo "" ;;
  esac
}
```

This is the built-in fallback if a base ships without `compatible-integrations.txt`. Keep both in sync.

### 8. Add `docs/bases/<base>.html`

Copy an existing page (`docs/bases/express-ts.html` is a good template) and adapt: when to choose, apply command, what lands table, compatible integrations table, recommended scripts, gotchas, smoke test.

Also add a card to `docs/bases/index.html` and a row to the supported-stacks table in `README.md`.

### 9. Verify

```bash
# Discovers the new base?
bash scripts/apply.sh --list

# Dry run produces a clean plan?
bash scripts/apply.sh --base=<base> --dry /tmp/test-base

# Real apply renders CLAUDE.md with no leftover {{placeholders}}?
bash scripts/apply.sh --base=<base> /tmp/test-base
grep -c "{{[A-Z]*}}" /tmp/test-base/CLAUDE.md   # should print 0

# Compatible integration still works?
bash scripts/apply.sh --base=<base> --integrations=<one> --dry /tmp/test-base
```

---

## Adding a new integration

Integrations layer on top of any compatible base. Pick a name, then:

### 1. Create the folder

```bash
mkdir -p overlays/integrations/<name>/.claude/rules
```

### 2. Add the rule file

`overlays/integrations/<name>/.claude/rules/<name>.md`. Same YAML frontmatter as base rules. Focus on **idioms and pitfalls** — Claude already knows the API. Cover:

- The one thing teams get wrong (RLS, security rules, listener cleanup, schema discipline…)
- Environment variable separation (which keys go where)
- Cleanup or migration patterns
- Common combinations (this integration + that one)

### 3. Add `env.snippet`

The env-var keys appended to the target's `.env.example`. Include comments explaining which ones are server-only:

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anon-key>
# Server-only — must NEVER be exposed to the browser
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

If the integration has no env vars (e.g. Tailwind), use a one-line comment:

```
# Tailwind has no environment variables.
```

### 4. Add `architecture.md`

A short paragraph appended to the target's `CLAUDE.md` under `## Integration: <name>`. Cover:

- Where the integration's code lives (`src/lib/<name>.ts`, `prisma/`, etc.)
- What's the source of truth for behavior (e.g., "RLS policies are the source of truth for authorization")
- Pointer back to the rule file

Keep it to 3–5 sentences.

### 5. Add `package.snippet.json`

Scripts and devDeps to merge. Don't add runtime deps (the user installs those when ready) — only dev tools and CLI utilities:

```json
{
  "scripts": {
    "db:generate": "prisma generate",
    "db:migrate": "prisma migrate dev"
  },
  "devDependencies": {
    "prisma": "^5.22.0"
  }
}
```

### 6. Add `compatible-with.txt`

Bases this integration supports, one per line:

```
express-js
express-ts
nestjs
nextjs-ts
```

(Used for docs and human-readable listings. The hard validation lives in `apply.sh`'s `compat_for()`.)

### 7. Update `scripts/apply.sh`

For every compatible base, add your integration to its list in `compat_for()`:

```bash
nextjs-ts)      echo "supabase firebase tailwind prisma trpc nextauth tanstack-query zod <your-name>" ;;
```

### 8. Add `docs/integrations/<name>.html`

Template: copy `docs/integrations/prisma.html` and adapt — compatible-bases table, env keys, rule-file highlights, combinations.

Also add a card to `docs/integrations/index.html` and a column to the compatibility matrix.

### 9. The additive-only rule

The first place this bites: never create a file path that the base or core already wrote. Run the conflict check:

```bash
# Use a compatible base and dry-run
bash scripts/apply.sh --base=<some-base> --integrations=<your-name> --dry /tmp/test

# If apply.sh exits with code 3 ("Integration would overwrite ..."), rename your file
# or move it into a unique subdirectory. Don't try to "merge" — that's a base concern.
```

---

## Adding a new preset

Presets are tiny — just a JSON alias for a base + integrations combo.

```bash
cat > presets/<name>.json <<'EOF'
{
  "name": "<name>",
  "description": "One sentence",
  "base": "<base-name>",
  "integrations": ["a", "b"],
  "tags": ["fullstack", "..."],
  "homepage": "https://example.com",
  "notes": "Anything special about this combo"
}
EOF
```

Verify:

```bash
bash scripts/apply.sh --preset=<name> --dry /tmp/test
```

Optionally add `docs/presets/<name>.html` if it's a preset you want documented (copy `docs/presets/firebase-react.html` as a template).

---

## Testing checklist

Before opening a PR, all of these should pass:

- [ ] `bash scripts/apply.sh --list` shows the new overlay or preset
- [ ] `bash scripts/apply.sh --base=<x> [--integrations=...] --dry /tmp/scratch` exits 0
- [ ] `bash scripts/apply.sh --base=<x> [--integrations=...] /tmp/real-test` writes the expected file count
- [ ] `grep '{{' /tmp/real-test/CLAUDE.md` returns nothing — no unsubstituted placeholders
- [ ] If you added a base: `cd /tmp/real-test && npm install && npm run validate` works (after you scaffold the framework on top)
- [ ] If you added an integration: applying it with two different compatible bases both succeed
- [ ] `cd examples/express-demo && npm install && npm test` still passes — you haven't broken the demo

## Style

- Match existing voice in rule files: direct, opinionated, concrete examples for good and bad.
- Markdown frontmatter uses three dashes and YAML.
- Indent JSON with 2 spaces.
- Bash uses `bash` shebang, `set -euo pipefail`, and lowercase function names.
- HTML docs use the shared `docs/assets/styles.css` — no inline styles, no per-page CSS.

## Questions

If you're unsure whether something belongs in core, a base, or an integration, the test is: **would every project benefit?** (core) **only every project of this framework?** (base) **only projects that opted in?** (integration). When in doubt, put it in a base and refactor up to core later if it generalises.
