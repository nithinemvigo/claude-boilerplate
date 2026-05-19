# Project Brain


## Stack
Node.js (v25 — see `.nvmrc`) | JavaScript | TypeScript
Supports: REST APIs, Next.js, React, Vue — update this section when applying to a specific project

## Commands
npm run dev | npm run build | npm test | npm run test:coverage | npm run lint | npm run lint:fix | npm run format | npm run format:check | npm run validate | npm run deps:audit | npm run deps:outdated

## Coding Standards
- Use `const` by default, `let` when mutation is needed, never `var`
- Prefer async/await over raw promises
- Error handling: always use try/catch with meaningful messages — see `.claude/rules/error-handling.md`
- Naming: camelCase for variables/functions, PascalCase for classes, SCREAMING_SNAKE for constants
- Max function length: 30 lines — refactor if exceeding
- Max file length: 300 lines — split into modules if exceeding

## Architecture
- `src/` — Application source code *(Update this mapping if copying to Next.js `app/`!)*
- `scripts/` — Build and automation scripts
- `.claude/hooks/` — Pre/post commit validation pipeline
- `.claude/commands/` — Reusable slash commands (`/project:<name>`)
- `.claude/agents/` — Agent personas (test-writer, doc-writer, etc.)
- `.claude/rules/` — Domain rules (API, database, security, etc.)
- `.agents/workflows/` — End-to-end workflows (new-feature, bug-fix, dependency-update)
- `.reviews/` — Generated review reports

## Testing Conventions
- Test files: `*.test.js` co-located with source files
- Framework: Jest + Supertest for HTTP endpoints
- Coverage target: 80%+ — run `npm run test:coverage`
- Always test: happy path, edge cases, error paths, security paths
- See `.claude/rules/testing.md` for detailed patterns
- See `.claude/rules/typescript.md` for TypeScript standards
- See `.claude/rules/frontend.md` for React/Vue/Next.js patterns

## Git Conventions
- Branch naming: `feature/`, `fix/`, `chore/`, `docs/`
- Commit format: conventional commits (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`)
- Always run `npm run lint:fix && npm run format` before committing

## Claude Hooks (replaces Husky)
Hooks are configured in `.claude/settings.json` and fire automatically during Claude sessions.

### Pipeline (triggered on every `git commit`)
1. **PreToolUse → `.claude/hooks/pre-commit-validate.sh`**
   - `[1/4]` ESLint — blocks commit on lint errors
   - `[2/4]` Prettier check — blocks commit on formatting issues
   - `[3/4]` `/security-review` (security-guidance plugin) on staged diff — blocks on injection, XSS, eval, hardcoded secrets, path traversal, etc.
   - `[4/4]` `/code-review` (code-review plugin) on staged diff — blocks if verdict is "Request Changes" or critical issues found
   - Tip: `npm run lint:fix` and `npm run format` to auto-fix before committing

2. **PostToolUse → `.claude/hooks/post-commit-review.sh`**
   - Saves a lightweight commit record to `.reviews/<commit-sha>.md` (review already ran pre-commit)

### Manual review
- `npm run review` — review the last commit
- `npm run review:commit -- <SHA>` — review a specific commit

### Customisation
- **Review criteria**: edit `.claude/review-prompt.md`
- **ESLint rules**: edit `eslint.config.js`
- **Prettier style**: edit `.prettierrc`

## Rules for Claude
- DO: Follow existing patterns in the codebase
- DO: Write tests for all new functions
- DO: Use existing utilities before creating new ones
- DO: Follow rules in `.claude/rules/` for domain-specific guidance
- DON'T: Introduce new dependencies without discussion
- DON'T: Modify `.claude/hooks/` without approval
- DON'T: Skip error handling
- DON'T: Hardcode secrets or credentials — use environment variables

## Token Optimization Tips
- Run `/compact` after completing logical sub-tasks
- Use `/clear` between unrelated tasks
- Use targeted prompts (specific files/lines, not "look at the codebase")
- Cap long CLI output: `npm test 2>&1 | head -50`
