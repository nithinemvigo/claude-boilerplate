---
description: End-to-end feature implementation from PRD to PR
---

# New Feature Workflow

## Inputs
- `$ARGUMENTS` = path to PRD file (markdown, Jira export, or description)

## Steps

### 1. Read & Analyze PRD
- Read the file at `$ARGUMENTS`
- Extract: feature name, acceptance criteria, scope, affected modules
- Summarize understanding and confirm with user before proceeding

### 2. Create Implementation Plan
- List all files to create/modify
- Define the approach for each change
- Identify risks and dependencies
- Present plan to user for approval

### 3. Create Feature Branch
// turbo
- Run: `git checkout -b feature/<feature-name-derived-from-prd>`

### 4. Implement Changes
- Make code changes following CLAUDE.md conventions and `.claude/rules/`
- Follow existing patterns in the codebase
- Add JSDoc comments for new exports
- Keep functions under 30 lines, files under 300 lines

### 5. Write/Update Tests
- Add unit tests for all new functions
- Add integration tests for new endpoints
- Follow patterns in existing `*.test.js` files
// turbo
- Run: `npm test` — all tests must pass

### 6. Lint & Format
// turbo
- Run: `npm run lint:fix`
// turbo
- Run: `npm run format`

### 7. Security Review
- Run `/security-review` on all changed files
- Fix any findings before proceeding

### 8. Code Review
- Run `/code-review` on all changed files
- Fix any issues, re-run until approved

### 9. Update Changelog
- Add entry to `CHANGELOG.md` under `## [Unreleased]`
- Format: `- feat: <description>`

### 10. Commit
- Stage all changes: `git add .`
- Commit with conventional message: `feat: <description>`
- The pre-commit hook will run full validation automatically

### 11. Push & Create PR
// turbo
- Run: `git push -u origin <branch-name>`
- Generate PR description using `.claude/agents/pr-description.md`
- If `gh` CLI is available: `gh pr create --title "feat: <title>" --body "<description>"`
- Otherwise, display the PR description for manual creation
