Scan the entire codebase for TODO, FIXME, HACK, XXX, and VULNERABILITY comments.

## Instructions
1. Search all `.js`, `.ts`, `.md`, `.sh` files (exclude `node_modules/`, `.reviews/`)
2. For each match, report:
   - **File** and **line number**
   - **Tag** (TODO / FIXME / HACK / XXX / VULNERABILITY)
   - **Full comment text**
3. Group by severity:
   - 🔴 FIXME / VULNERABILITY — must be addressed
   - 🟡 HACK / XXX — technical debt
   - 🟢 TODO — future work
4. End with a summary count: `X critical, Y debt, Z future`
