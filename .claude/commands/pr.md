Draft a pull request description from the current branch's changes.

## Instructions
1. Get the current branch name: `git branch --show-current`
2. Get the diff against the base branch: `git diff main...HEAD --stat` and `git log main..HEAD --oneline`
3. Generate a PR description with:

### Title
Derive from branch name (e.g., `feature/user-auth` → `feat: Add user authentication`)

### Description
- **What** — Summary of changes (2-3 sentences)
- **Why** — Problem being solved or feature being added
- **How** — Key implementation decisions

### Changes
- Bullet list of files changed with one-line descriptions

### Testing
- What tests were added/updated
- How to manually verify

### Checklist
- [ ] Tests pass (`npm test`)
- [ ] Lint clean (`npm run lint`)
- [ ] Formatted (`npm run format:check`)
- [ ] No security issues
- [ ] CHANGELOG updated
