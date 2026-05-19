---
description: End-to-end feature implementation from PRD to PR
---

# New Feature Workflow

## Inputs
- `$ARGUMENTS` = path to PRD file (markdown, Jira export, or description)

## Plugins used
- **gstack** — `/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/ship`
- **superpowers** — `/brainstorm`, `/write-plan`, `/execute-plan`

## Pre-commit pipeline (automatic — do NOT run manually)
> Runs automatically on every `git commit` via `.claude/hooks/pre-commit-validate.sh`
> - [1/4] ESLint
> - [2/4] Prettier
> - [3/4] `/security-review` — blocks on vulnerabilities
> - [4/4] `/code-review`    — blocks if verdict is "Request Changes"
> Reports saved to `.reviews/` automatically.

---

## Steps

### 1. Understand & Validate the PRD
- Read the file at `$ARGUMENTS`
- Extract: feature name, acceptance criteria, scope, affected modules
- Run `/office-hours` with the PRD summary
  → Product brainstorm: validates the idea, surfaces edge cases, questions assumptions
- Run `/plan-ceo-review` with the PRD
  → Strategy sign-off: confirms scope, priority, and success criteria
- **Stop here** — confirm understanding with the user before proceeding

### 2. Brainstorm Approach
- Run `/brainstorm` (superpowers) with the confirmed feature scope
  → Explores implementation alternatives before committing to one
  → Surfaces trade-offs, risks, and dependencies
- Present options to user for direction

### 3. Architecture Review
- Run `/plan-eng-review` (gstack) with the chosen approach
  → Eng Manager validates architecture, data model, service boundaries
- Run `/plan-design-review` if the feature touches UI or API contracts
- Document decisions as an ADR using `/engineering:architecture` if significant

### 4. Write Implementation Plan
- Run `/write-plan` (superpowers) with the validated approach
  → Produces a step-by-step plan: files to create/modify, order of changes, test strategy
- Present plan to user for approval
- **Stop here** — do not write any code until the plan is approved

### 5. Create Feature Branch
// turbo
- Run: `git checkout -b feature/<feature-name-derived-from-prd>`

### 6. Execute Plan (TDD)
- Run `/execute-plan` (superpowers) — follows the approved plan from Step 4
- superpowers enforces TDD: write failing test → implement → go green (YAGNI + DRY)
- For each change:
  1. Write the failing test first
  2. Implement the minimum code to make it pass
  3. Refactor if needed — keep functions under 30 lines, files under 300 lines
- Follow `.claude/rules/` for domain-specific guidance

### 7. Run Full Test Suite
// turbo
- Run: `npm test` — all tests must pass
- Run: `npm run test:coverage` — coverage must stay above 80%

### 8. Lint & Format
// turbo
- Run: `npm run lint:fix && npm run format`

### 9. Update Changelog
- Add entry to `CHANGELOG.md` under `## [Unreleased]`
- Format: `- feat: <description>`

### 10. Commit
// turbo
- Run: `git add . && git commit -m "feat: <description>"`
- Pre-commit hook fires automatically:
  - ESLint + Prettier gate
  - `/security-review` → blocks if vulnerabilities found
  - `/code-review`     → blocks if verdict is "Request Changes"
- If blocked: fix only what the hook reported, then re-run this step
- Reports saved to `.reviews/` for audit trail

### 11. Push & Create PR
// turbo
- Run: `git push -u origin <branch-name>`
- Run `/ship` (gstack) — Release Manager creates the PR with structured description,
  links to the PRD, and tags reviewers
- Fallback if `/ship` unavailable:
  - Generate PR description using `.claude/agents/pr-description.md`
  - Run: `gh pr create --title "feat: <title>" --body "<description>"`
