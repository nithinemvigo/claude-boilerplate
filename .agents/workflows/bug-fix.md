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
- Run: `echo -e "\033[1;36m🚀 [1/5] Creating branch fix/... \033[0m" && git checkout -b fix/<bug-name-or-ticket-id>`

### 3. Implement the Fix
- Fix the root cause (not just the symptom)
- Follow CLAUDE.md conventions and `.claude/rules/`
- Keep the fix minimal — change only what's necessary
- Update `CHANGELOG.md` under `## [Unreleased]`, Format: `- fix: <description>`

### 4. Lint & Format
// turbo
- Run: `echo -e "\033[1;36m✨ [2/5] Running ESLint and Prettier... \033[0m" && npm run lint:fix && npm run format`

### 5. Security & Code Review
- Run `/security-review` on changed files
- Run `/code-review` on changed files
- Fix any issues found
// turbo
- Call `echo -e "\033[1;36m🛡️  [3/5] Starting Pre-commit validation... \033[0m" && echo '{"tool_input":{"command":"git commit -m \"dummy\""}}' | bash .claude/hooks/pre-commit-validate.sh`
// turbo
- Then commit: `echo -e "\033[1;32m📦 [4/5] Committing changes... \033[0m" && git commit -m "fix: <description>"`

### 6. Create Pull Request
// turbo
- Run: `echo -e "\033[1;35m🚀 [5/5] Pushing to Git... \033[0m" && git push -u origin <branch-name>`
- Generate PR description using `.claude/agents/pr-description.md`
