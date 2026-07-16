# Claude Boilerplate

> Composable Claude Code starter — agents, hooks, skills, and rules that snap into any Node, Express, NestJS, React, or Next.js project with a single command.

A `core/` of always-on Claude tooling, plus stack-specific **bases** (Express JS/TS, NestJS, React+Vite, Next.js) and additive **integrations** (Supabase, Firebase, Tailwind, Prisma). Compose them with `scripts/apply.sh` or pick a named **preset**.

---

## Quick start

### Option A — npx (no clone required)

```bash
# Scaffold your project (whatever framework)
npx create-next-app@latest my-app --typescript --app

# Apply the boilerplate on top
npx create-claude-boilerplate nextjs-ts ./my-app supabase tailwind
```

### Option B — clone and apply

```bash
# 1. Clone this repo somewhere
git clone <repo-url> ~/tools/claude-boilerplate

# 2. Scaffold your project (whatever framework)
npx create-next-app@latest my-app --typescript --app
# (or: npm create vite@latest, npx @nestjs/cli new, etc.)

# 3. Apply the boilerplate on top — pick one of:
bash ~/tools/claude-boilerplate/create.sh nextjs-ts ./my-app supabase tailwind
# or the explicit form:
bash ~/tools/claude-boilerplate/scripts/apply.sh --base=nextjs-ts --integrations=supabase,tailwind ./my-app
```

That's it. `my-app` now has `.claude/`, `CLAUDE.md`, env keys, merged `package.json` scripts, and stack-specific rules wired up.

### Option C — drop into an EXISTING repo

If you already have a project with `package.json`, `src/`, etc., use `apply-to-existing.sh` — it copies only files that aren't already there and prints a per-file merge plan for the conflicts:

```bash
bash ~/tools/claude-boilerplate/scripts/apply-to-existing.sh \
  --base=express-ts --integrations=prisma \
  /path/to/your/existing/repo
```

It auto-appends unique lines to `.gitignore` and `.env.example`, leaves your `package.json` and ESLint config untouched, and saves a staging copy at `.claude-boilerplate-staging/` for diffing during merge.

### Presets — opinionated bundles

```bash
bash scripts/apply.sh --preset=t3-stack          ./my-app
bash scripts/apply.sh --preset=supabase-nextjs   ./my-app
bash scripts/apply.sh --preset=firebase-react    ./my-app
```

See available stacks any time with `bash scripts/apply.sh --list`.

### Required plugins (one-time per machine)

The pre-commit pipeline calls two Claude Code plugins. Install once, globally:

```bash
claude /plugins install https://claude.com/plugins/security-guidance
claude /plugins install https://claude.com/plugins/code-review
```

If either plugin is missing, the pre-commit hook **skips that gate with a loud warning** rather than blocking your commit — so you can keep working while you sort out installation. Set `CLAUDE_BOILERPLATE_STRICT=1` in your shell to make missing plugins a hard failure instead.

After `apply.sh` finishes, run `npm run check-setup` in the target project to verify Node, the `claude` CLI, both plugins, and the hook wiring in one shot.

---

## Supported stacks

| Base | Language | Use case |
|---|---|---|
| [`express-js`](docs/bases/express-js.html) | JavaScript | Node + Express REST API |
| [`express-ts`](docs/bases/express-ts.html) | TypeScript | Node + Express, typed |
| [`nestjs`](docs/bases/nestjs.html) | TypeScript | NestJS with DI, modules, decorators |
| [`react-vite-ts`](docs/bases/react-vite-ts.html) | TypeScript | React + Vite SPA |
| [`nextjs-ts`](docs/bases/nextjs-ts.html) | TypeScript | Next.js App Router, fullstack |

| Integration | Layers on |
|---|---|
| [`supabase`](docs/integrations/supabase.html) | any base — Postgres + Auth + Storage + Realtime |
| [`firebase`](docs/integrations/firebase.html) | any base — Auth + Firestore + Storage |
| [`tailwind`](docs/integrations/tailwind.html) | frontend bases only — utility-first CSS |
| [`prisma`](docs/integrations/prisma.html) | server bases (incl. `nextjs-ts`) — type-safe ORM |

| Preset | Expands to |
|---|---|
| [`t3-stack`](docs/presets/t3-stack.html) | `nextjs-ts` + `tailwind`,`trpc`,`prisma`,`nextauth`,`zod` (tRPC/NextAuth/Zod arrive in v2) |
| [`supabase-nextjs`](docs/presets/supabase-nextjs.html) | `nextjs-ts` + `supabase` |
| [`firebase-react`](docs/presets/firebase-react.html) | `react-vite-ts` + `firebase` |

The compatibility matrix (which integrations work with which bases) and the v2 roadmap live at [docs/apply.html](docs/apply.html).

---

## What you get

After `apply.sh` runs, every target project has:

- **14 specialized agents** in `.claude/agents/` — `planner`, `implementer`, `code-reviewer`, `qa-tester`, `unit-tester`, etc.
- **1 slash command** in `.claude/commands/` — `/pipeline` orchestrates the end-to-end SDLC.
- **4 hooks** in `.claude/hooks/` — pre-commit validation (lint → format → `/security-review` → `/code-review`), post-commit record, status line, plugin probe (graceful degradation when plugins are missing).
- **Layered rules** in `.claude/rules/` — `error-handling`, `security`, `environment`, `testing` from core, plus framework-specific (e.g. `frontend`, `api`, `nextjs-conventions`) from the base, plus integration-specific (e.g. `supabase`, `tailwind`) from each integration.
- **2 helper scripts** in `scripts/` — `check-setup.sh` (verify env + plugins), `review.sh` (manual code review).
- A populated `CLAUDE.md` — Project context placeholders + Stack/Commands/Architecture/Anti-patterns filled from the base + integration paragraphs appended.
- `.env.example` with placeholder keys for every integration.
- `package.json` with `lint`, `format`, `test`, `validate`, `review`, `check-setup` scripts already wired up.

Concrete example — `--base=nextjs-ts --integrations=supabase,tailwind,prisma` lands ~40 files.

---

## Running a task

`/pipeline <description>` is the universal entry point for any change:

```text
/pipeline add Stripe subscription billing to checkout
/pipeline fix the auth token expiry crash on refresh
/pipeline hotfix the null-pointer in payment-service
/pipeline refactor user service into smaller modules
```

What happens:

1. **Classification & Setup**: The orchestrator classifies the task (nano vs standard) and asks for testing preferences.
2. **Planning**: Dispatches `planner` (or `investigator` for bugs) to create a detailed plan.
3. **Review & Approval**: The plan is reviewed by specialized agents (`ceo-reviewer`, `eng-reviewer`, `design-reviewer`). *You must approve the plan before execution begins.*
4. **Execution**: Dispatches `implementer` sequentially to work through tasks on a branch, optionally using TDD.
5. **Quality Gates**: Runs `unit-tester` and `qa-tester` to verify behavior and test coverage.
6. **Code Review**: Analyzes the diff with `code-reviewer` and `security-reviewer`.
7. **Ship**: Updates documentation and creates a PR.

**The commit rule:** only the **doc-writer** or final **implementer** is permitted to issue `git commit` as guided by the `/pipeline` orchestrator.

For the full SDLC pipeline, see the `core/.claude/commands/pipeline.md` definition.

---

## The pre-commit pipeline

Every `git commit` in a target project triggers `.claude/hooks/pre-commit-validate.sh`:

1. **ESLint** — blocks on lint errors.
2. **Prettier check** — blocks on formatting drift.
3. **`/security-review`** — blocks on injection, XSS, hardcoded secrets, path traversal.
4. **`/code-review`** — blocks if the verdict is "Request Changes" or critical issues are found.

Reports save to `.reviews/<commit-sha>.md` automatically. The commit is rejected if any gate fails — no need for Husky or pre-commit framework setup.

If either plugin is missing, that gate **degrades to a warning** rather than blocking the commit (set `CLAUDE_BOILERPLATE_STRICT=1` to fail hard instead). Run `npm run check-setup` any time to verify Node, the `claude` CLI, both plugins, and the hook wiring.

---

## Plugins to install

Claude Code plugins these workflows assume:

- **gstack** — `/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review`, `/ship` ([github.com/garrytan/gstack](https://github.com/garrytan/gstack))
- **superpowers** — `/brainstorm`, `/write-plan`, `/execute-plan`
- **security-guidance** — powers the `/security-review` step in the pre-commit hook
- **code-review** — powers the `/code-review` step

The pipeline still runs if a plugin is missing — that gate just gets skipped with a warning.

---

## Repo anatomy

```
claude-boilerplate/
├── core/                     ← copied to every target (14 agents, 1 command, 4 hooks, generic rules, CLAUDE template, helper scripts)
├── overlays/
│   ├── bases/                ← one per project (express-js, express-ts, nestjs, react-vite-ts, nextjs-ts)
│   └── integrations/         ← zero or more per project (supabase, firebase, tailwind, prisma)
├── presets/                  ← named base + integrations bundles
├── examples/express-demo/    ← runnable demo with deliberate bugs the security pipeline catches
├── docs/                     ← documentation site (HTML, no build step)
├── scripts/
│   ├── apply.sh              ← composer for NEW project directories
│   └── apply-to-existing.sh  ← safe-merge into an EXISTING repo
├── create.sh                 ← friendly wrapper: bash create.sh <base> <target> [integrations…]
├── bin/create.js             ← npx wrapper: npx create-claude-boilerplate <base> <target>
├── README.md                 ← this file
├── CLAUDE.md                 ← instructions for editing the boilerplate itself
└── CONTRIBUTING.md           ← how to add a new base, integration, or preset
```

Full breakdown: [`docs/folders.html`](docs/folders.html).

---

## Customizing

For a target project, the most common edits after `apply.sh`:

1. **`CLAUDE.md`** — review the Architecture section, add project-specific notes.
2. **`.env.example`** — fill in real keys, copy to `.env`.
3. **`.claude/rules/*.md`** — adapt the integration rule files to your team's conventions.
4. **`eslint.config.js`** — relax rules that don't match your codebase.

For the boilerplate repo itself, see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Documentation

The full documentation site lives in `docs/` — plain HTML, no build step. Open [`docs/index.html`](docs/index.html) in any browser.

| Page | Covers |
|---|---|
| [`docs/index.html`](docs/index.html) | Overview, composition model, four combination examples |
| [`docs/folders.html`](docs/folders.html) | Every directory in this repo explained |
| [`docs/apply.html`](docs/apply.html) | Full `apply.sh` contract — flags, compatibility, errors, anatomy, FAQ |
| [`docs/bases/`](docs/bases/index.html) | Per-base page with files added, rules, scripts, gotchas |
| [`docs/integrations/`](docs/integrations/index.html) | Per-integration page with env keys, compatible bases, rule highlights |
| [`docs/presets/`](docs/presets/index.html) | Per-preset page with expansion + workflow |

For Markdown rendering on GitHub: [`docs/apply-composition.md`](docs/apply-composition.md) mirrors `apply.html`.

---

## License

ISC.
