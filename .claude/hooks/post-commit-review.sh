#!/usr/bin/env bash
# Claude PostToolUse hook — automated code review after git commit
#
# Fires after every Bash tool call. Exits 0 immediately for anything
# that wasn't a git commit. For commits it calls 'claude --print' to
# generate a review and saves it to .reviews/<sha>.md.

set -euo pipefail

# ── Read the JSON payload Claude sends via stdin ──────────────────
INPUT=$(cat)

# Extract the bash command that just ran
COMMAND=$(echo "$INPUT" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" \
  2>/dev/null || echo "")

# Only run review after git commit commands
if ! echo "$COMMAND" | grep -qE '(^|&&[[:space:]]*|;[[:space:]]*)git commit'; then
  exit 0
fi

# ── Config ────────────────────────────────────────────────────────
REVIEW_DIR=".reviews"
PROMPT_FILE=".claude/review-prompt.md"
CLAUDE_CMD="claude"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Preflight: need claude CLI
if ! command -v "$CLAUDE_CMD" &>/dev/null; then
  echo -e "${YELLOW}⚠ Claude CLI not found. Skipping code review.${NC}"
  exit 0
fi

# ── Gather Commit Info ────────────────────────────────────────────
COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null) || { echo -e "${YELLOW}⚠ Not a git repo. Skipping.${NC}"; exit 0; }
COMMIT_SHORT=$(git rev-parse --short HEAD)
COMMIT_MSG=$(git log -1 --pretty=%B)
COMMIT_AUTHOR=$(git log -1 --pretty=%an)
COMMIT_DATE=$(git log -1 --pretty=%ci)
FILES_CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD | head -20)

# Get the diff (cap at 8000 lines to avoid token overflow)
DIFF=$(git diff HEAD~1 HEAD 2>/dev/null \
  || git show HEAD --format="" 2>/dev/null \
  || echo "No diff available (initial commit?)")
DIFF=$(echo "$DIFF" | head -8000)

if [ -z "$DIFF" ] || [ "$DIFF" = "No diff available (initial commit?)" ]; then
  echo -e "${YELLOW}⚠ No diff to review. Skipping.${NC}"
  exit 0
fi

# ── Build Review Prompt ───────────────────────────────────────────
REVIEW_PROMPT="$(cat "$PROMPT_FILE" 2>/dev/null \
  || echo "Review the following commit for bugs, security issues, and code quality.")"

FULL_PROMPT="$REVIEW_PROMPT

---

## Commit Details

- **SHA:** $COMMIT_SHORT
- **Author:** $COMMIT_AUTHOR
- **Date:** $COMMIT_DATE
- **Message:** $COMMIT_MSG

### Files Changed
$FILES_CHANGED

### Diff
\`\`\`diff
$DIFF
\`\`\`"

# ── Run Claude Review ─────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🔍 Claude Code Reviewer                ║${NC}"
echo -e "${CYAN}║   Reviewing commit $COMMIT_SHORT             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

mkdir -p "$REVIEW_DIR"
REVIEW_FILE="$REVIEW_DIR/${COMMIT_SHORT}.md"

REVIEW_OUTPUT=$(echo "$FULL_PROMPT" | $CLAUDE_CMD --print 2>&1) || {
  echo -e "${YELLOW}⚠ Claude review failed. Commit was still saved.${NC}"
  exit 0
}

# ── Save & Display ────────────────────────────────────────────────
{
  echo "# Code Review — \`$COMMIT_SHORT\`"
  echo ""
  echo "| Field | Value |"
  echo "|-------|-------|"
  echo "| **Commit** | \`$COMMIT_SHA\` |"
  echo "| **Author** | $COMMIT_AUTHOR |"
  echo "| **Date** | $COMMIT_DATE |"
  echo "| **Message** | $COMMIT_MSG |"
  echo ""
  echo "---"
  echo ""
  echo "$REVIEW_OUTPUT"
} > "$REVIEW_FILE"

echo "$REVIEW_OUTPUT"
echo ""
echo -e "${GREEN}✅ Review saved to ${REVIEW_FILE}${NC}"
echo ""
exit 0
