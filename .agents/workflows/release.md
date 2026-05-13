---
description: Release workflow — version bump, changelog, tag, push
---

# Release Workflow

## Inputs
- `$ARGUMENTS` = version bump type: `patch`, `minor`, or `major`

## Steps

### 1. Pre-flight Checks
// turbo
- Run: `npm test` — all tests must pass
// turbo
- Run: `npm run lint` — no lint errors
// turbo
- Run: `npm run format:check` — all files formatted
- Ensure working directory is clean: `git status`
- Ensure on `main` branch: `git branch --show-current`

### 2. Version Bump
- Update version in `package.json` based on `$ARGUMENTS`:
  - `patch`: 1.0.0 → 1.0.1
  - `minor`: 1.0.0 → 1.1.0
  - `major`: 1.0.0 → 2.0.0

### 3. Finalize Changelog
- Move items under `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD`
- Add a new empty `## [Unreleased]` section at the top

### 4. Commit Release
- Stage: `git add package.json package-lock.json CHANGELOG.md`
- Commit: `git commit -m "chore: release vX.Y.Z"`

### 5. Tag
// turbo
- Run: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`

### 6. Push
// turbo
- Run: `git push origin main --follow-tags`

### 7. Post-release
- Display release summary with version, date, and key changes
