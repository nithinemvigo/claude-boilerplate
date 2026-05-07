# Project Brain

## Stack
Nodejs

## Commands
npm run dev | npm run build | npm test | npm run lint | npm run format | npm run format:check

## Claude Hooks (replaces Husky)
Hooks are configured in `.claude/settings.json` and fire automatically during Claude sessions.

### Pipeline (triggered on every `git commit`)
1. **PreToolUse → `.claude/hooks/pre-commit-validate.sh`**
   - Runs ESLint (`npx eslint .`) — blocks commit on errors
   - Runs Prettier check (`npx prettier --check .`) — blocks commit on formatting issues
   - Tip: `npm run lint:fix` and `npm run format` to auto-fix before committing

2. **PostToolUse → `.claude/hooks/post-commit-review.sh`**
   - Runs Claude code review on the committed diff
   - Saves review to `.reviews/<commit-sha>.md`

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
