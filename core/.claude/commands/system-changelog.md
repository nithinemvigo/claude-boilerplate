Generate a detailed changelog entry tracking internal system extension modifications.

## Instructions
1. Run `git log --oneline -15 -- core/.claude overlays/bases` to get all recent commits modifying rules, hooks, commands, or agents in the boilerplate structure.
2. Group the modifications logically:
   - **🧠 Agents & Commands** — changes to `.claude/commands/`
   - **🛡️ Hooks & Pipelines** — changes to `.claude/hooks/`
   - **📜 Rules (Core)** — changes to `core/.claude/rules/`
   - **📜 Rules (Bases)** — changes to framework base rules
3. Read the modifications using `git show [commit-hash]` if you need more context on complex rule updates.
4. Format your output as a professional changelog entry.
5. Identify the `CHANGELOG.md` inside `core/.claude/CHANGELOG.md` and dynamically prepend your new entry to the top of the `## [Unreleased]` block.
6. Provide a brief summary statement to the user of what was documented.
