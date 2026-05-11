# Project Brain

## Stack
Nodejs

## Commands
npm run dev | npm run build | npm test | npm run lint | npm run format | npm run format:check

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

### Cleanup
The `.husky/` directory is no longer needed. Remove it with:
```
git rm -r .husky
```
