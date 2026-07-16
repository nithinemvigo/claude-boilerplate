# Claude Boilerplate — Repo Instructions

> **Read me first if you're editing this repo itself.** These instructions are for working *on the boilerplate*. The template that becomes the *target project's* `CLAUDE.md` lives at `core/CLAUDE.template.md` — don't confuse the two.

## What this repo is

A composable Claude Code starter. A `core/` of agents, commands, hooks, and skills (always copied to every target), plus stack-specific **bases** and additive **integrations** that compose on top. The `scripts/apply.sh` composer stitches them into any new project.

See `docs/index.html` for the public-facing overview.

## Repo layout

```
core/                              ← copied into every target project, untouched per target
  .claude/agents/                   14 specialized core agents (planner, implementer, reviewer, tester, etc)
  .claude/commands/                 1 slash command (/pipeline)
  .claude/hooks/                    pre-commit + post-commit + statusline + plugin-probe
  .claude/rules/                    generic rules (error-handling, security, environment, testing)
  .claude/skills/                   shared skill definitions copied to target projects
  .claude/CHANGELOG.md              changelog for rules, hooks, and commands in the boilerplate
  .claude/review-prompt.md          prompt used by the post-commit review hook
  scripts/                          target-side helpers (check-setup.sh, review.sh)
  CLAUDE.template.md                4 placeholders: {{STACK}}, {{COMMANDS}}, {{ARCHITECTURE}}, {{ANTIPATTERNS}}
overlays/bases/<name>/             ← pick exactly one per target
overlays/integrations/<name>/      ← pick zero or more per target — additive only
presets/<name>.json                ← named base + integrations bundles
examples/express-demo/             ← runnable demo (deliberate bugs for the security pipeline to catch)
docs/                              ← documentation site (HTML, no build step)
scripts/apply.sh                   ← the composer for new project directories
scripts/apply-to-existing.sh       ← safe-merge wrapper for existing repos
package.json                       ← npm publish manifest for `npx create-claude-js-boilerplate`
create.sh, bin/create.js           ← friendly wrappers (bash + npx)
```

Full breakdown: `docs/folders.html`.

## How to work on this repo

### Adding a new base

1. Create `overlays/bases/<name>/`.
2. Add framework-specific rule files under `.claude/rules/` (e.g., `frontend.md`, `api.md`, `nestjs-conventions.md`).
3. Add a flat `eslint.config.js`.
4. Add `tsconfig.recommended.json` if it's a TypeScript base.
5. Add `package.scripts.json` with the framework's scripts and devDeps.
6. Add `CLAUDE.fragment.md` with exactly four sections matching the template placeholders:
   ```
   ## {{STACK}}
   <stack description as a bullet list>

   ## {{COMMANDS}}
   <commands grouped by purpose: Dev loop / Quality / Database / Preflight / Review / Maintenance>

   ## {{ARCHITECTURE}}
   <tree + "What goes where" table + base-specific notes>

   ## {{ANTIPATTERNS}}
   <"Looks right but is wrong" — concrete, framework-specific>
   ```
7. Add `compatible-integrations.txt` — one integration name per line.
8. Update the `COMPAT[]` map in `scripts/apply.sh` for this base.
9. Add `docs/bases/<name>.html` (copy an existing page and adapt).
10. Verify: `bash scripts/apply.sh --base=<name> --dry /tmp/test-<name>`.

### Adding a new integration

1. Create `overlays/integrations/<name>/`.
2. Add `.claude/rules/<name>.md` with your team's idioms and pitfalls for this integration.
3. Add `env.snippet` — the env-var keys to append to `.env.example`.
4. Add `architecture.md` — the paragraph appended to the target's `CLAUDE.md`.
5. Add `package.snippet.json` if there are devDeps or scripts to merge.
6. Add `compatible-with.txt` listing the bases this integration supports.
7. Update the `COMPAT[]` map in `scripts/apply.sh` for each compatible base.
8. Add `docs/integrations/<name>.html`.
9. Verify: `bash scripts/apply.sh --base=<base> --integrations=<name> --dry /tmp/test-<name>`.

**Critical constraint:** integrations must be **additive only**. They must never overwrite a file owned by `core/` or a base. `apply.sh` enforces this with exit code `3`. If you need to override behavior, fix the base, not the integration.

### Adding a new preset

Drop a JSON file in `presets/<name>.json`:

```json
{
  "name": "my-preset",
  "description": "Short blurb",
  "base": "<base-name>",
  "integrations": ["a", "b"],
  "tags": ["fullstack", "..."]
}
```

Verify: `bash scripts/apply.sh --preset=<name> --dry /tmp/test`.

Optionally add `docs/presets/<name>.html` if it's a preset you want documented.

## Testing changes

Quick checks while iterating:

- `bash scripts/apply.sh --list` — confirms a new overlay or preset is discovered
- `bash scripts/apply.sh --base=<name> --dry /tmp/scratch` — preview what apply would do
- `bash scripts/apply.sh --base=<name> /tmp/real-test` — real apply, then `cd /tmp/real-test && npm install && npm run validate`
- `cd examples/express-demo && npm install && npm test` — verify the demo still works

`apply.sh` exits non-zero on any error class:
- `2` — incompatible combination
- `3` — file conflict during integration copy
- `4` — base / integration / preset not found
- `1` — usage error

## Rules for Claude editing this repo

- **DO** preserve git history with `git mv` when moving files.
- **DO** keep `core/` stack-agnostic. Any rule that mentions a specific framework belongs in a base, not in core.
- **DO** keep integrations additive. If an integration needs to override a file, the design is wrong — fix the base instead.
- **DO** update `docs/` whenever you add, rename, or remove a base / integration / preset.
- **DO** run `apply.sh` against a scratch target whenever you change `core/`, an overlay, or the script itself.
- **DO** keep the v1 scope honest: bases = `express-js`, `express-ts`, `nestjs`, `react-vite-ts`, `nextjs-ts`; integrations = `supabase`, `firebase`, `tailwind`, `prisma`; presets = `t3-stack`, `supabase-nextjs`, `firebase-react`.
- **DON'T** edit files under `core/.claude/hooks/` without testing — they fire on every commit in *every* target project. A broken hook there breaks everyone.
- **DON'T** add stack-specific content to `core/CLAUDE.template.md`. Use `{{STACK}}` / `{{COMMANDS}}` / `{{ARCHITECTURE}}` / `{{ANTIPATTERNS}}` placeholders instead.
- **DON'T** ship starter code in integrations by default — keep them rules + env + architecture. Starter code drifts when SDKs change. (A `--starter` flag is reserved for v2.)
- **DON'T** add runtime or dev dependencies to the root `package.json`. It exists solely as the npm publish manifest for `npx create-claude-js-boilerplate` (the `bin/create.js` entry point). `examples/express-demo/` is the demo Node project with its own `package.json`.

## Hooks on this repo

The boilerplate's own `.claude/` is gone from the repo root after the reorganisation. `core/.claude/settings.json` is the *template* — it lands in target projects, not in this repo. That means hooks **don't fire when you commit inside this repo**. This is intentional — you don't want the demo's pipeline gating boilerplate edits.

If you want hook coverage while editing the boilerplate, symlink `core/.claude` to `./.claude` locally:

```bash
ln -s core/.claude .claude
```

That symlink is gitignored (suggested addition to `.gitignore` if you adopt the workflow).

## v1 vs v2 scope

**v1 (current):**
- Bases: `express-js`, `express-ts`, `nestjs`, `react-vite-ts`, `nextjs-ts`
- Integrations: `supabase`, `firebase`, `tailwind`, `prisma`
- Presets: `t3-stack` (declared, errors cleanly until v2 integrations exist), `supabase-nextjs`, `firebase-react`

**v2 (planned):**
- Additional bases: `node-js`, `node-ts`, `react-js`, `react-ts`, `nextjs-js`
- Additional integrations: `trpc`, `nextauth`, `tanstack-query`, `zod`
- `--starter` flag to optionally include integration scaffolding code
- `.claude/boilerplate.lock.json` written on first apply to enable safe re-apply / upgrade

When promoting something from v2 to v1, update both this file and `docs/`.

## Documentation

The documentation site lives at `docs/` — plain HTML, no build step. Open `docs/index.html` in a browser.

Key pages:
- `docs/index.html` — landing
- `docs/folders.html` — every folder explained
- `docs/apply.html` — full `apply.sh` contract
- `docs/bases/<name>.html` — per-base detail (5 pages)
- `docs/integrations/<name>.html` — per-integration detail (4 pages)
- `docs/presets/<name>.html` — per-preset detail (3 pages)
- `docs/apply-composition.md` — Markdown mirror of `apply.html` (for GitHub rendering)

## Token Optimization Tips for editing this repo

- Use `/compact` after completing logical sub-tasks (e.g., after adding one new overlay).
- Run `bash scripts/apply.sh --list` instead of `find overlays/` to inspect available stacks.
- Use targeted prompts (specific files, not "look at the boilerplate").
- Don't dump large JSON files into context — read the schema, then edit.
