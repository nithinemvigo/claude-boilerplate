# Claude Code Universal Boilerplate

A production-ready Claude Code project skeleton with automated code review, security scanning, end-to-end agents, and workflow playbooks.

**This boilerplate works for Node.js, Express, React, Next.js, and TypeScript projects.** It establishes a "brain" for Claude Code to understand your specific rules and automatically enforce code quality.

*(Note: The `src/` directory and `src/index.js` file provided here are solely for demonstrating the automated code review pipeline catching vulnerabilities. They are NOT required for your actual project).*

---

## 🚀 How to Apply This Boilerplate to YOUR Project

1. **Copy the brain:** Copy the `.claude/` and `.agents/` folders, and the `CLAUDE.md` file from this repo into the root folder of your project (React, Next.js, TS, etc.).
2. **Update the Brain (if needed):** Open `CLAUDE.md` in your project and update the "Stack" and "Architecture" sections to match your actual framework (e.g., mention Next.js App Router, or React components folder structure).
3. **Copy configurations (Optional):** We recommend copying `.nvmrc`, `.editorconfig`, and `.env.example`.
4. **Trigger the hooks:** Our validation pipeline intercepts `git commit`. Ensure you are using Claude Code to commit, or manually configure the scripts in your `package.json`.

**For TypeScript or Frontend Frameworks:** No deep structural changes are required! The AI agents and rules are entirely Markdown-based, so Claude natively reads them and applies the rules perfectly whether you write Node.js endpoints or React components.

---

## 🤖 Workflows & Agents

Workflows are heavily structured, automated step-by-step playbooks guiding Claude from ideation to pull request.

### How to run an agent workflow
You can run a workflow inside the Claude Code terminal by explicitly telling Claude to follow the playbook.
```text
Follow the workflow in .agents/workflows/new-feature.md to implement a user login page...
```
*(Tip: In supported editors, you can also use slash commands like `/new-feature path/to/prd.md`)*

### Available Workflows & Agents Leveraged

| Workflow Playbook | Trigger | What It Does & Which Agents It Uses |
|----------|---------|-------------|
| **New Feature** | `.agents/workflows/new-feature.md` | PRD → plan → branch → implement → test → review → PR. Uses: `pr-description.md` agent. |
| **Dependency Update** | `.agents/workflows/dependency-update.md` | Audit → update → test → commit |

### Agents (Personas)
Invoke specialized agent personas by telling Claude to "Act as...":
- **Test Writer:** *"Act as the test-writer agent and write tests for src/components/Button.tsx"*
- **Doc Writer:** *"Follow .claude/agents/doc-writer.md to document this module"*

---

## 🛡️ Pre-Commit Validation Pipeline (Hooks)

Every time Claude Code (or you, if configured) attempts a `git commit`, the `.claude/hooks/pre-commit-validate.sh` hook intercepts it.

**The Pipeline:**
1. **ESLint** — blocks on syntax/lint issues
2. **Prettier** — blocks on formatting drift
3. **Security Scan** — Analyzes the diff using Claude's security plugins for injections, hardcoded secrets, XSS.
4. **Code Review** — Analyzes the diff for logical bugs, perf problems, and code quality.

*(You can also run this manually before committing by directly referencing the script!).*

---

## 📚 Core Plugins Used
To get maximum value, install these core plugins in your Claude CLI:
1. **Frontend Design** — `claude.com/plugins/frontend-design`
2. **Code Review** — `claude.com/plugins/code-review`
3. **Security Review** — `claude.com/plugins/security-guidance`
4. **Gstack** — `github.com/garrytan/gstack`

*(The security and code review hooks automatically rely on the plugin models to grade your commits!).*

---

## 🛠 Project Structure Overview

```text
├── .claude/
│   ├── hooks/              # Pre/post commit validation scripts
│   ├── commands/           # Slash commands (/project:<name>)
│   ├── agents/             # Agent personas
│   ├── rules/              # Domain-specific coding rules
│   └── settings.json       # Hook configuration
├── .agents/workflows/      # End-to-end master playbooks
├── CLAUDE.md               # Essential instructions & context
├── example/                # HTML tutorial on boilerplate usage
└── src/                    # Demo API with deliberate bugs to test the hooks!
```
