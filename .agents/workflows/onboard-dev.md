---
description: New developer onboarding guide
---

# Onboard Developer Workflow

## Steps

### 1. Environment Setup
- Ensure Node.js version matches `.nvmrc`: `nvm use`
- Install dependencies: `npm install`
- Copy environment template: `cp .env.example .env`
- Edit `.env` with local configuration values

### 2. Verify Setup
// turbo
- Run: `npm test` — all tests should pass
// turbo
- Run: `npm run lint` — should be clean
// turbo
- Run: `npm run dev` — server should start on the configured port

### 3. Project Overview
- Read `CLAUDE.md` for coding standards and conventions
- Read `README.md` for project overview
- Explore key files:
  - `src/index.js` — main application entry point
  - `src/index.test.js` — example test patterns
  - `.claude/rules/` — domain-specific coding rules
  - `.claude/commands/` — available slash commands
  - `.claude/agents/` — agent personas

### 4. Understand the Pipeline
- Every `git commit` triggers the pre-commit pipeline:
  1. ESLint check
  2. Prettier check
  3. Security scan (security-guidance plugin)
  4. Code review (code-review plugin)
- Reviews are saved to `.reviews/`

### 5. Try Key Commands
- `/project:explain src/index.js` — understand the main file
- `/project:todo-scan` — see pending TODOs
- `/project:test src/index.js` — generate tests for a file
- `npm run review` — manually trigger a code review

### 6. First Task
- Pick a small issue or TODO from the codebase
- Follow `.agents/workflows/bug-fix.md` or `.agents/workflows/new-feature.md`
- The pipeline will guide you through the rest
