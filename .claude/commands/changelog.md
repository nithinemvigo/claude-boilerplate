Generate a changelog entry from recent git commits.

## Instructions
1. Read the last 10 commits using `git log --oneline -10`
2. Group commits by type using conventional commit prefixes:
   - **✨ Features** — `feat:`
   - **🐛 Bug Fixes** — `fix:`
   - **📝 Documentation** — `docs:`
   - **🔧 Chores** — `chore:`
   - **♻️ Refactors** — `refactor:`
   - **🧪 Tests** — `test:`
3. Format as a Keep a Changelog entry under `## [Unreleased]`
4. If `CHANGELOG.md` exists, prepend the new entry. If not, create it.
5. Include the date in ISO format
