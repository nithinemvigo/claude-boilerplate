---
description: Safely update project dependencies
---

# Dependency Update Workflow

## Steps

### 1. Audit Current State
// turbo
- Run: `npm audit` — check for known vulnerabilities
// turbo
- Run: `npm outdated` — list outdated packages
- Summarize findings: critical vulns, high vulns, outdated count

### 2. Create Update Branch
// turbo
- Run: `git checkout -b chore/dependency-update`

### 3. Fix Security Vulnerabilities First
- Run: `npm audit fix` for automatic fixes
- For breaking changes requiring manual fixes, update one at a time:
  - Read the package's changelog for breaking changes
  - Update the dependency
  - Run tests after each update
  - Fix any breaking changes

### 4. Update Outdated Packages
- Update patch/minor versions: `npm update`
- For major version bumps:
  - Review the changelog for breaking changes
  - Update one major version at a time
  - Test after each update

### 5. Verify
// turbo
- Run: `npm test` — all tests must pass
// turbo
- Run: `npm run lint` — no lint errors
// turbo
- Run: `npm audit` — confirm vulnerabilities resolved

### 6. Commit & PR
- Commit: `git add . && git commit -m "chore: update dependencies"`
- Push and create PR with summary of changes
