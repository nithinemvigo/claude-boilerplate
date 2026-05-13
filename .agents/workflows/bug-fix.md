---
description: Bug fix workflow from report to PR
---

# Bug Fix Workflow

## Inputs
- `$ARGUMENTS` = path to bug report file, Jira ticket link, or description of the bug

## Steps

### 1. Analyze Bug Report
- Read the bug report at `$ARGUMENTS`
- Extract: steps to reproduce, expected vs actual behavior, affected area
- Identify the likely root cause location in codebase

### 2. Reproduce the Bug
- Write a failing test that demonstrates the bug
// turbo
- Run: `npm test` — confirm the new test fails as expected

### 3. Create Fix Branch
// turbo
- Run: `git checkout -b fix/<bug-name-or-ticket-id>`

### 4. Implement the Fix
- Fix the root cause (not just the symptom)
- Follow CLAUDE.md conventions and `.claude/rules/`
- Keep the fix minimal — change only what's necessary

### 5. Verify Fix
// turbo
- Run: `npm test` — the previously failing test must now pass
- Ensure no existing tests broke

### 6. Add Regression Tests
- Add edge case tests around the fix to prevent regression
// turbo
- Run: `npm test` — all tests pass

### 7. Lint & Format
// turbo
- Run: `npm run lint:fix && npm run format`

### 8. Security & Code Review
- Run `/security-review` on changed files
- Run `/code-review` on changed files
- Fix any issues found

### 9. Update Changelog
- Add entry to `CHANGELOG.md` under `## [Unreleased]`
- Format: `- fix: <description>`

### 10. Commit & PR
- Stage and commit: `git add . && git commit -m "fix: <description>"`
- Push: `git push -u origin <branch-name>`
- Generate PR description using `.claude/agents/pr-description.md`
