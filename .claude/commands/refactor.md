Analyze $ARGUMENTS for refactoring opportunities. **Do NOT apply changes** — only suggest.

## What to look for
1. **Long functions** (> 30 lines) — suggest extraction
2. **Deep nesting** (> 3 levels) — suggest early returns or extraction
3. **Code duplication** — identify repeated patterns across files
4. **God objects/files** — files doing too many things (> 300 lines)
5. **Poor naming** — vague variables (`data`, `temp`, `x`) or misleading names
6. **Missing abstractions** — repeated patterns that could be a utility
7. **Complex conditionals** — long if/else chains that could be maps or strategies

## Output format
For each suggestion, provide:
- **Location**: file:line
- **Issue**: what's wrong
- **Suggestion**: how to fix it
- **Priority**: 🔴 High / 🟡 Medium / 🟢 Low
- **Effort**: estimated lines of change
