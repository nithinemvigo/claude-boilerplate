Analyze the cyclomatic complexity and cognitive complexity of functions in $ARGUMENTS.

## Instructions
1. Read the target file
2. For each function, calculate:
   - **Cyclomatic complexity** — count of independent paths (if/else, switch, loops, &&, ||)
   - **Cognitive complexity** — nesting depth, breaks in linear flow
   - **Lines of code** (excluding comments/blanks)
3. Flag functions exceeding thresholds:
   - 🔴 Complexity > 15 — must refactor
   - 🟡 Complexity 8–15 — should simplify
   - 🟢 Complexity < 8 — acceptable
4. Output a table:
   | Function | Cyclomatic | Cognitive | LOC | Rating |
5. Suggest specific refactoring for any 🔴 or 🟡 functions
