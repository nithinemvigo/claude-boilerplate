#!/usr/bin/env bash
# Claude PreToolUse hook — ESLint + Prettier + code-review gate for git commits
#
# Pipeline (all three must pass before the commit is allowed):
#   [1/3] ESLint        — blocks on lint errors
#   [2/3] Prettier      — blocks on formatting issues
#   [3/3] /code-review  — blocks if verdict is "Request Changes" (critical issues found)

set -euo pipefail

# ── Read the JSON payload Claude sends via stdin ──────────────────
INPUT=$(cat)

COMMAND=$(echo "$INPUT" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" \
  2>/dev/null || echo "")

# Only gate on git commit commands; let everything else through
if ! echo "$COMMAND" | grep -qE '(^|&&[[:space:]]*|;[[:space:]]*)git commit'; then
  exit 0
fi

# ── Colors ────────────────────────────────────────────────────────
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🔍 Pre-Commit Validation               ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── [1/3] ESLint ──────────────────────────────────────────────────
echo -e "${BOLD}[1/3] ESLint${NC}"
if ! npx eslint . 2>&1; then
  echo ""
  echo -e "${RED}❌ ESLint failed. Fix errors before committing.${NC}"
  echo -e "${YELLOW}   Tip: npm run lint:fix${NC}"
  exit 2
fi
echo -e "${GREEN}✅ ESLint passed${NC}"
echo ""

# ── [2/3] Prettier ────────────────────────────────────────────────
echo -e "${BOLD}[2/3] Prettier${NC}"
if ! npx prettier --check . 2>&1; then
  echo ""
  echo -e "${RED}❌ Prettier check failed.${NC}"
  echo -e "${YELLOW}   Tip: npm run format${NC}"
  exit 2
fi
echo -e "${GREEN}✅ Prettier passed${NC}"
echo ""

# ── [3/3] Code Review (Anthropic code-review plugin) ─────────────
echo -e "${BOLD}[3/3] Code Review${NC}"

CLAUDE_CMD="claude"
if ! command -v "$CLAUDE_CMD" &>/dev/null; then
  echo -e "${YELLOW}⚠ Claude CLI not found. Skipping code review.${NC}"
  exit 0
fi

# Get staged diff (what's about to be committed)
STAGED_DIFF=$(git diff --cached 2>/dev/null || echo "")

if [ -z "$STAGED_DIFF" ]; then
  echo -e "${YELLOW}⚠ No staged changes to review.${NC}"
  exit 0
fi

STAGED_DIFF=$(echo "$STAGED_DIFF" | head -8000)
FILES_STAGED=$(git diff --cached --name-only | head -20)

REVIEW_PROMPT="/code-review

Review the following staged changes that are about to be committed.

### Files Staged
$FILES_STAGED

### Staged Diff
\`\`\`diff
$STAGED_DIFF
\`\`\`

After your review, end with a clear verdict line in this exact format:
VERDICT: Approve
or
VERDICT: Request Changes
or
VERDICT: Needs Discussion"

echo -e "Running /code-review on staged diff..."
echo ""

REVIEW_OUTPUT=$(echo "$REVIEW_PROMPT" | $CLAUDE_CMD --print 2>&1) || {
  echo -e "${YELLOW}⚠ Code review failed to run. Proceeding with commit.${NC}"
  exit 0
}

# Display the full review
echo "$REVIEW_OUTPUT"
echo ""

# ── Parse verdict ─────────────────────────────────────────────────
# Check for explicit VERDICT line or "Request Changes" anywhere in output
if echo "$REVIEW_OUTPUT" | grep -qiE "VERDICT:[[:space:]]*(Request Changes|Needs Discussion)"; then
  echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
  echo -e "${RED}║  🚫 Commit blocked by code review        ║${NC}"
  echo -e "${RED}║  Fix the issues above and try again.     ║${NC}"
  echo -e "${RED}╚══════════════════════════════════════════╝${NC}"
  exit 2
fi

# Also block if Critical Issues section has table rows (beyond the header)
if echo "$REVIEW_OUTPUT" | grep -qE "###[[:space:]]*Critical Issues" && \
   echo "$REVIEW_OUTPUT" | grep -qE "^\|[[:space:]]*[0-9]+[[:space:]]*\|"; then
  echo -e "${RED}╔══════════════════════════════════════════╗${NC}"
  echo -e "${RED}║  🚫 Commit blocked — critical issues     ║${NC}"
  echo -e "${RED}║  Fix the issues above and try again.     ║${NC}"
  echo -e "${RED}╚══════════════════════════════════════════╝${NC}"
  exit 2
fi

echo -e "${GREEN}✅ Code review passed${NC}"
echo ""
echo -e "${GREEN}✅ All checks passed — proceeding with commit.${NC}"
echo ""
exit 0
