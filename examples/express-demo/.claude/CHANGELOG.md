# Claude System Extensions Changelog

All notable changes to the Claude Code superpowers (rules, hooks, commands, formatting) in this boilerplate will be documented in this file.

This format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to Semantic Versioning.

## [Unreleased]

### ✨ Added
- New `/changelog` slash command to automate changelog maintenance in applied projects.
- New `code-review.md` ensemble code reviewer tool for deep pre-commit linting.
- New unified `.claude/CHANGELOG.md` to track changes in rules, hooks, and commands.

### 🧪 Changed
- Modified `pre-commit-validate.sh` to fail fast and require `security-guidance` and `code-review` plugins.

## Architecture

System extensions in this boilerplate are modularized as follows:
- **Commands**: \`.claude/commands/*.md\` (Slash commands and agents)
- **Hooks**: \`.claude/hooks/*.sh\` (Git hooks like pre-commit)
- **Rules**: \`.claude/rules/*.md\` (Contextual rules per framework layered via \`apply.sh\`)

Always run \`/changelog\` after deploying updates to this directory to keep track of system behavioral changes.
