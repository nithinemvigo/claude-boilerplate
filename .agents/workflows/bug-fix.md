---
description: Bug fix workflow from report to PR (No testing steps)
---

# Bug Fix Workflow

## Inputs
- `$ARGUMENTS` = path to bug report file, Jira ticket link, or description of the bug

## Steps

### 1. Analyze Bug Report
- Read the bug report at `$ARGUMENTS`
- Extract: expected vs actual behavior, affected area
- Identify the likely root cause location in the codebase

### 2. Create Fix Branch
// turbo
- Run: `git checkout -b fix/<bug-name-or-ticket-id>`

### 3. Implement the Fix
- Fix the root cause (not just the symptom)
- Follow CLAUDE.md conventions and `.claude/rules/`
- Keep the fix minimal — change only what's necessary
- Update `CHANGELOG.md` under `## [Unreleased]`, Format: `- fix: <description>`

### 4. Lint & Format
// turbo
- Run: `npm run lint:fix && npm run format`

### 5. Security & Code Review
- Run `/security-review` on changed files
- Run `/code-review` on changed files
- Fix any issues found
// turbo
- Call `echo '{"tool_input":{"command":"git commit -m \"dummy\""}}' | bash .claude/hooks/pre-commit-validate.sh` to call precommit-validate
// turbo
- Then commit: `git commit -m "fix: <description>"`

### 6. Create Pull Request
// turbo
- Run: `git push -u origin <branch-name>`
- Generate PR description using `.claude/agents/pr-description.md`
