# claude-boilerplate

A production-ready Claude Code project skeleton with automated code review, security scanning, and best-practice tooling.

## Quick Start

```bash
git clone https://github.com/nithinemvigo/claude-boilerplate.git
cd claude-boilerplate
nvm use          # Use Node.js version from .nvmrc
npm install
cp .env.example .env   # Configure environment variables
npm run dev      # Start development server
```

## Plugins

Install these core plugins in Claude Code:

1. **Superpowers** — [github.com/obra/superpowers](http://github.com/obra/superpowers)
2. **Frontend Design** — [claude.com/plugins/frontend-design](http://claude.com/plugins/frontend-design)
3. **Code Review** — https://claude.com/plugins/code-review
4. **Security Review** — https://claude.com/plugins/security-guidance
5. **Claude Mem** — [github.com/nicholasgasior/claude-mem](http://github.com/nicholasgasior/claude-mem)
6. **Gstack** — [github.com/garrytan/gstack](http://github.com/garrytan/gstack)

## Available Commands

### npm Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start development server |
| `npm test` | Run tests |
| `npm run test:coverage` | Run tests with coverage report |
| `npm run lint` | Check linting |
| `npm run lint:fix` | Auto-fix lint issues |
| `npm run format` | Format code with Prettier |
| `npm run format:check` | Check formatting |
| `npm run validate` | Full validation (lint + format + test) |
| `npm run review` | Review the last commit |
| `npm run review:commit -- <SHA>` | Review a specific commit |
| `npm run deps:audit` | Check for dependency vulnerabilities |
| `npm run deps:outdated` | List outdated packages |

### Slash Commands

Trigger with `/project:<command>` in Claude Code:

| Command | Description |
|---------|-------------|
| `/project:explain <file>` | Explain a file or module in detail with diagrams |
| `/project:test <file>` | Generate tests following existing patterns |
| `/project:doc <file>` | Add/update JSDoc documentation |
| `/project:refactor <file>` | Analyze refactoring opportunities (no auto-apply) |
| `/project:todo-scan` | Find all TODO/FIXME/HACK comments |
| `/project:changelog` | Generate changelog from recent commits |
| `/project:pr` | Draft a PR description from current branch |
| `/project:deps-audit` | Audit dependencies for vulnerabilities |
| `/project:complexity <file>` | Analyze function complexity |

## Agents

Invoke agents by referencing them in Claude Code:

| Agent | How to Use |
|-------|-----------|
| **Test Writer** | *"Act as the test-writer agent and write tests for src/index.js"* |
| **Doc Writer** | *"Follow .claude/agents/doc-writer.md to document this module"* |
| **Refactor Advisor** | *"Act as the refactor-advisor agent and analyze src/"* |
| **PR Description** | *"Follow .claude/agents/pr-description.md to describe my changes"* |
| **Onboarding Guide** | *"Act as the onboarding-guide agent for a new team member"* |

## Rules

Domain-specific rules in `.claude/rules/` are auto-loaded by Claude:

| Rule | Covers |
|------|--------|
| `api.md` | REST conventions, request/response format, CORS, rate limiting |
| `database.md` | Connection pooling, parameterized queries, migrations, transactions |
| `security.md` | Input sanitization, auth patterns, secrets, OWASP, HTTP headers |
| `error-handling.md` | try/catch patterns, custom errors, graceful shutdown, logging |
| `testing.md` | Jest patterns, coverage targets, mocking, test isolation |
| `environment.md` | Environment variables, .env files, naming conventions |

## Workflows

End-to-end automation triggered with slash commands:

| Workflow | Trigger | What It Does |
|----------|---------|-------------|
| **New Feature** | `/new-feature path/to/prd.md` | PRD → plan → branch → implement → test → review → PR |
| **Bug Fix** | `/bug-fix path/to/report.md` | Bug report → failing test → fix → regression test → PR |
| **Release** | `/release patch\|minor\|major` | Version bump → changelog → tag → push |
| **Dependency Update** | `/dependency-update` | Audit → update → test → commit |
| **Onboard Dev** | `/onboard-dev` | New developer setup walkthrough |

## 🔍 Pre-Commit Pipeline (Auto on Commit)

Every `git commit` triggers a 4-step validation pipeline:

1. **ESLint** — blocks on lint errors
2. **Prettier** — blocks on formatting issues
3. **Security Scan** — blocks on injection, XSS, hardcoded secrets, etc.
4. **Code Review** — blocks on "Request Changes" or critical issues

Reviews are saved to `.reviews/<sha>.md`.

### Manual Review

```bash
npm run review              # Review the last commit
npm run review:commit -- abc1234   # Review a specific commit
```

## Project Structure

```
├── src/                    # Application source code
├── scripts/                # Automation scripts
├── .claude/
│   ├── hooks/              # Pre/post commit validation
│   ├── commands/           # Slash commands (/project:<name>)
│   ├── agents/             # Agent personas
│   ├── rules/              # Domain-specific coding rules
│   ├── review-prompt.md    # Code review criteria
│   └── settings.json       # Hook configuration
├── .agents/workflows/      # End-to-end workflows
├── .reviews/               # Generated review reports
├── CLAUDE.md               # Project conventions & standards
├── .nvmrc                  # Node.js version lock
├── .editorconfig           # Cross-IDE editor settings
└── .env.example            # Environment variable template
```

## Customization

- **Review criteria**: edit `.claude/review-prompt.md`
- **ESLint rules**: edit `eslint.config.js`
- **Prettier style**: edit `.prettierrc`
- **Domain rules**: add/edit files in `.claude/rules/`
- **Slash commands**: add/edit files in `.claude/commands/`
- **Agent personas**: add/edit files in `.claude/agents/`
- **Workflows**: add/edit files in `.agents/workflows/`

## Custom Skills Installation

### Global Installation (All Projects)
```bash
git clone <YOUR_FORK_URL> ~/.claude/skills/<custom-skills-folder>
```

### Local Installation (This Project Only)
```bash
git clone <YOUR_FORK_URL> .claude/skills/<custom-skills-folder>
```

## Prerequisites

- [Node.js](https://nodejs.org/) v25+ (use `nvm use`)
- [Claude CLI](https://docs.anthropic.com/claude-cli) installed and authenticated
