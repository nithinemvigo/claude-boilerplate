# Claude Boilerplate

> Composable Claude Code starter — agents, hooks, skills, and rules that snap into any Node, Express, NestJS, React, or Next.js project with a single command.

A `core/` of always-on Claude tooling, plus stack-specific **bases** (Express JS/TS, NestJS, React+Vite, Next.js) and additive **integrations** (Supabase, Firebase, Tailwind, Prisma). Compose them with `scripts/apply.sh` or pick a named **preset**.

---

## Quick start

```bash
# 1. Clone this repo somewhere
git clone <repo-url> ~/tools/claude-js-boilerplate

# 2. Scaffold your project (whatever framework)
npx create-next-app@latest my-app --typescript --app
# (or: npm create vite@latest, npx @nestjs/cli new, etc.)

# 3. Apply the boilerplate on top
bash ~/tools/claude-js-boilerplate/scripts/apply.sh \
  --base=nextjs-ts --integrations=supabase,tailwind \
  ./my-app
```

That's it. `my-app` now has `.claude/`, `.agents/`, `CLAUDE.md`, env keys, merged `package.json` scripts, and stack-specific rules wired up.

Prefer a named bundle? Use a preset:

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

- **4 agent personas** in `.claude/agents/` — `test-writer`, `doc-writer`, `pr-description`, `onboarding-guide`.
- **7 slash commands** in `.claude/commands/` — `/feature`, `/pr`, `/test`, `/doc`, `/explain`, `/changelog`, `/code-review`.
- **3 hooks** in `.claude/hooks/` — pre-commit validation (lint → format → `/security-review` → `/code-review`), post-commit record, status line.
- **1 skill** in `.claude/skills/ui-ux-pro-max/` — design intelligence (67 styles, 96 palettes, 99 UX guidelines, 13 tech stacks). Auto-triggers on UI work.
- **2 workflows** in `.agents/workflows/` — `new-feature.md` (PRD → PR in 11 steps), `dependency-update.md`.
- **Layered rules** in `.claude/rules/` — `error-handling`, `security`, `environment`, `testing` from core, plus framework-specific (e.g. `frontend`, `api`, `nextjs-conventions`) from the base, plus integration-specific (e.g. `supabase`, `tailwind`) from each integration.
- A populated `CLAUDE.md` — Stack/Commands/Architecture filled from the base, with an integration paragraph appended for each one.
- `.env.example` with placeholder keys for every integration.
- `package.json` with `lint`, `format`, `test`, `validate` scripts already wired up.

Concrete example — `--base=nextjs-ts --integrations=supabase,tailwind,prisma` lands **38 files**, 11 of them rules.

---

## Running a workflow

Three ways:

```bash
# 1. Slash command (in Claude Code)
/feature path/to/prd.md

# 2. Explicit prompt
Follow the workflow in .agents/workflows/new-feature.md to implement <X>

# 3. Step-by-step
# Open .agents/workflows/new-feature.md and run each step manually
```

The `new-feature` workflow uses `/office-hours`, `/plan-ceo-review`, `/brainstorm`, `/plan-eng-review`, `/write-plan`, `/execute-plan`, and `/ship` from the **gstack** and **superpowers** plugins, plus the `pr-description` agent as a fallback.

---

## The pre-commit pipeline

Every `git commit` in a target project triggers `.claude/hooks/pre-commit-validate.sh`:

1. **ESLint** — blocks on lint errors.
2. **Prettier check** — blocks on formatting drift.
3. **`/security-review`** — blocks on injection, XSS, hardcoded secrets, path traversal.
4. **`/code-review`** — blocks if the verdict is "Request Changes" or critical issues are found.

Reports save to `.reviews/<commit-sha>.md` automatically. The commit is rejected if any gate fails — no need for Husky or pre-commit framework setup.

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
claude-js-boilerplate/
├── core/                     ← copied to every target (agents, commands, hooks, skills, generic rules, CLAUDE template)
├── overlays/
│   ├── bases/                ← one per project (express-js, express-ts, nestjs, react-vite-ts, nextjs-ts)
│   └── integrations/         ← zero or more per project (supabase, firebase, tailwind, prisma)
├── presets/                  ← named base + integrations bundles
├── examples/express-demo/    ← runnable demo with deliberate bugs the security pipeline catches
├── docs/                     ← documentation site (HTML, no build step)
├── scripts/apply.sh          ← the composer
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
