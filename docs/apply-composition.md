# Applying the Boilerplate — Composition Guide

> How `scripts/apply.sh` composes a project from a **base** stack plus zero or more **integrations**, what lands on disk, and how invalid combinations are caught.

---

## Table of Contents

1. [The composition model](#the-composition-model)
2. [How combinations work](#how-combinations-work)
   - [Example 1 — React TS + Supabase](#example-1--react-ts--supabase)
   - [Example 2 — Next.js TS + Firebase + Tailwind](#example-2--nextjs-ts--firebase--tailwind)
   - [Example 3 — T3 Stack (preset)](#example-3--t3-stack-preset)
   - [Example 4 — NestJS + Prisma + Supabase](#example-4--nestjs--prisma--supabase)
3. [The `apply.sh` contract](#the-applysh-contract)
4. [Compatibility matrix](#compatibility-matrix)
5. [Flags and modes](#flags-and-modes)
6. [Conflict & error model](#conflict--error-model)
7. [Anatomy of a target project after apply](#anatomy-of-a-target-project-after-apply)
8. [FAQ](#faq)

---

## The composition model

Every project bootstrapped from this boilerplate is built from three layers, applied in this order:

| Layer | How many | Owns |
|---|---|---|
| **`core/`** | always exactly one | Stack-agnostic agents, commands, hooks, skills, generic rules (error-handling, security, environment, testing), the `CLAUDE.md` template, and editor/prettier configs. |
| **Base** (`overlays/bases/<base>/`) | exactly one per project | Framework files: ESLint config, tsconfig, `.nvmrc`, `package.json` scripts, framework-specific rules (`frontend.md`, `api.md`, `nestjs-conventions.md`, etc.), and the `CLAUDE.md` fragment for Stack / Commands / Architecture. |
| **Integrations** (`overlays/integrations/<name>/`) | zero or more per project | **Additive only.** A new rule file in `.claude/rules/`, env-var keys for `.env.example`, and an Architecture paragraph appended to `CLAUDE.md`. Integrations never overwrite files the base wrote. |

**Presets** (`presets/<name>.json`) are simply named aliases that expand to a base + a list of integrations. They add no new content of their own.

---

## How combinations work

### Example 1 — React TS + Supabase

```bash
bash scripts/apply.sh --base=react-ts --integrations=supabase ../my-app
```

**What lands in `../my-app`:**

- `core/` — every stack-agnostic file (agents, commands, hooks, skills, generic rules, `CLAUDE.template.md`).
- `overlays/bases/react-ts/` — `frontend.md` rule, `typescript.md` rule, React-flavored `eslint.config.js`, recommended `tsconfig.json`, scripts merged into `package.json`.
- `overlays/integrations/supabase/` — `supabase.md` rule, Supabase env keys appended to `.env.example`, an Architecture paragraph appended to `CLAUDE.md`, and (optionally, behind a flag) a `src/lib/supabase.ts` starter.

### Example 2 — Next.js TS + Firebase + Tailwind

```bash
bash scripts/apply.sh --base=nextjs-ts --integrations=firebase,tailwind ../my-app
```

Two integrations layered in the order listed. Firebase first, Tailwind second. Order matters only for the rendered `CLAUDE.md` Architecture section (paragraphs append in order).

### Example 3 — T3 Stack (preset)

```bash
bash scripts/apply.sh --preset=t3-stack ../my-app
```

A preset is just a named expansion. The command above is equivalent to:

```bash
bash scripts/apply.sh \
  --base=nextjs-ts \
  --integrations=tailwind,trpc,prisma,nextauth,zod \
  ../my-app
```

Presets live in `presets/<name>.json` and are the recommended way to share an opinionated combination across teams.

### Example 4 — NestJS + Prisma + Supabase

```bash
bash scripts/apply.sh --base=nestjs --integrations=prisma,supabase ../my-app
```

Both integrations are compatible with the `nestjs` base (`prisma` works with any TS server; `supabase` is flexible and only warns on bare-Node bases).

---

## The `apply.sh` contract

The script runs these steps in order. Any step failing aborts the run with a non-zero exit code and leaves the target untouched (no partial copies).

### 1. Validate the combo

Some integrations are framework-specific. The script enforces this **before copying any files**:

- `nextauth` requires `base ∈ {nextjs-js, nextjs-ts}`
- `trpc` requires `base ∈ {nextjs-*, express-*, nestjs}`
- `tailwind` requires `base ∈ {react-*, nextjs-*}`
- `supabase` and `firebase` are flexible; the script **warns** if `base=node-*` (bare Node without Express is unusual for these and can be bypassed with `--force`)

Each base overlay ships a `compatible-integrations.txt` listing the integrations it supports. The script checks the requested integrations against that list and exits with a clear error if any aren't allowed.

### 2. Copy `core/` to target

The entire `core/` tree is copied into the target directory. This is the always-on baseline.

### 3. Copy `overlays/bases/<base>/`

The selected base overlay is copied on top of `core/`. **Bases may override files from `core/`** — that's expected (e.g., a base ships its own `package.json` scripts that build on the core editor configs).

### 4. Copy each `overlays/integrations/<name>/`

For each integration in the order listed, copy its files into the target.

> **Conflict rule:** if an integration tries to write a file that already exists from `core/` or the base, the script **aborts** rather than overwrite. A conflict signals the integration is broken — integrations must be **additive only**.

### 5. Merge `package.json`

Deep-merge `"scripts"` and `"devDependencies"` from every layer into the target's `package.json`. If a key collides, the highest layer wins (`integrations` > `base` > `core`), and a warning is printed naming each colliding key.

### 6. Render `CLAUDE.md`

Substitute the base fragment into the placeholders inside `core/CLAUDE.template.md` (`{{STACK}}`, `{{COMMANDS}}`, `{{ARCHITECTURE}}`), then append each integration's Architecture paragraph in the order they were listed.

### 7. Append `.env.example` keys

Each integration's `.env.example` snippet is appended to the project's `.env.example`. Duplicate keys are deduplicated; the first occurrence wins.

### 8. Print a summary

A summary report is printed at the end:

```
✓ Applied base `nextjs-ts` + integrations [`supabase`, `tailwind`]
  Files added: 23  ·  Files modified: 3
  Next steps:
    1. cd ../my-app
    2. npm install
    3. Fill in Supabase keys in .env
    4. Run npm run validate
```

### 9. Dry-run mode (`--dry`)

`--dry` runs steps 1–8 in plan-only mode: nothing is written to disk. The summary lists every file the real run would create, modify, or leave alone. Use this before applying to an existing project.

---

## Compatibility matrix

Quick reference. Detailed compatibility for each base lives in its `compatible-integrations.txt`.

|              | supabase | firebase | tailwind | prisma | trpc | nextauth | tanstack-query | zod |
|--------------|:--------:|:--------:|:--------:|:------:|:----:|:--------:|:--------------:|:---:|
| express-js   | ✓        | ✓        | —        | ✓      | ✓    | —        | —              | ✓   |
| express-ts   | ✓        | ✓        | —        | ✓      | ✓    | —        | —              | ✓   |
| nestjs       | ✓        | ✓        | —        | ✓      | ✓    | —        | —              | ✓   |
| react-vite-ts| ✓        | ✓        | ✓        | —      | —    | —        | ✓              | ✓   |
| nextjs-ts    | ✓        | ✓        | ✓        | ✓      | ✓    | ✓        | ✓              | ✓   |
| node-* (v2)  | ⚠️ warn  | ⚠️ warn  | —        | ✓      | —    | —        | —              | ✓   |

Legend: ✓ supported · — not applicable (hard error) · ⚠️ allowed with warning, override with `--force`.

---

## Flags and modes

| Flag | Purpose |
|---|---|
| `--base=<name>` | Required unless `--preset` is used. One of the base names in `overlays/bases/`. |
| `--integrations=<a,b,c>` | Optional. Comma-separated list of integration names. Order determines the `CLAUDE.md` Architecture order. |
| `--preset=<name>` | Use a named preset from `presets/`. Mutually exclusive with `--base`/`--integrations`. |
| `--dry` | Plan-only mode. No files written. Prints the full diff that *would* be applied. |
| `--force` | Bypass the soft warnings (e.g., `firebase` on a bare-Node base). Hard errors (incompatible combos) are **never** bypassable. |
| `--target=<path>` | Explicit target directory. The last positional argument is used if this flag is omitted. |
| `--starter` | (Optional, v2) Include integration starter files (e.g., `src/lib/supabase.ts`). Off by default — keeps overlays SDK-version-agnostic. |
| `-h`, `--help` | Print usage and exit. |

---

## Conflict & error model

The script distinguishes three failure modes:

| Class | Example | Behavior |
|---|---|---|
| **Hard error — combo invalid** | `nextauth` with `--base=nestjs` | Abort before touching the target. Exit code `2`. |
| **Hard error — file conflict** | An integration tries to overwrite a base file | Abort mid-run. Roll back any files written so far. Exit code `3`. |
| **Soft warning** | `firebase` with `--base=node-ts` | Print warning. Continue. Exit code `0`. `--force` silences the warning. |

The target directory is never left in a half-applied state. Every step that writes files is staged in a temporary directory and only moved into place after step 8 succeeds.

---

## Anatomy of a target project after apply

For `--base=nextjs-ts --integrations=supabase,tailwind`:

```
my-app/
├── .claude/
│   ├── agents/                  ← from core
│   ├── commands/                ← from core
│   ├── hooks/                   ← from core
│   ├── skills/ui-ux-pro-max/    ← from core
│   ├── rules/
│   │   ├── error-handling.md    ← core
│   │   ├── security.md          ← core
│   │   ├── environment.md       ← core
│   │   ├── testing.md           ← core
│   │   ├── frontend.md          ← base (nextjs-ts)
│   │   ├── typescript.md        ← base (nextjs-ts)
│   │   ├── nextjs-conventions.md← base (nextjs-ts)
│   │   ├── api.md               ← base (nextjs-ts, trimmed for route handlers)
│   │   ├── supabase.md          ← integration
│   │   └── tailwind.md          ← integration
│   ├── settings.json            ← core
│   └── review-prompt.md         ← core
├── .agents/workflows/           ← core
├── .editorconfig                ← core
├── .gitignore                   ← core
├── .prettierrc                  ← core
├── .nvmrc                       ← base
├── eslint.config.js             ← base
├── tsconfig.json                ← base (recommended values)
├── package.json                 ← base scripts + integration devDeps, merged
├── .env.example                 ← base + integration keys appended
└── CLAUDE.md                    ← template + base fragment + integration paragraphs
```

No application code (`src/`, `app/`, `pages/`) is created. The boilerplate is a **brain**, not a scaffold — you bring your own framework-init step (`create-next-app`, `nest new`, `npm create vite`) and run `apply.sh` on top of the result.

---

## FAQ

**Can I run `apply.sh` on an existing project that already has files?**
Yes. Use `--dry` first to preview every file that would be written or modified. The script will warn before overwriting any file that the boilerplate is responsible for. Application code is never touched.

**What if I want a combination that isn't in `presets/`?**
Use `--base` and `--integrations` directly. If the combo is one your team uses often, drop a JSON file in `presets/` so the next person can use a short name.

**Can I write my own integration?**
Yes — create a folder under `overlays/integrations/<name>/`. The only requirements: (a) every file you add must be a *new* file not owned by `core/` or any base; (b) include a `compatible-with.txt` listing the bases your integration supports; (c) include a one-paragraph `architecture.md` that gets appended to `CLAUDE.md`. See `CONTRIBUTING.md`.

**How do I upgrade an existing project when the boilerplate gets new rules?**
Re-run `apply.sh` with the same flags. The script reads `.claude/boilerplate.lock.json` (written on first apply) to recover the original base + integrations, then re-applies the latest versions. Files you've edited locally are flagged in the dry-run report so you can merge by hand.

**Why no starter code in integrations by default?**
SDKs change. A `src/lib/supabase.ts` that ships with the overlay will drift the moment Supabase publishes a new client. Keeping integrations to rules + env keys means the boilerplate ages well. Use `--starter` (v2) when you explicitly want scaffolding.

---

*Last updated: 2026-05-19. See also: `README.md` (overview), `docs/workflows.md` (running agents), `docs/agents-and-skills.md` (reference).*
