#!/usr/bin/env bash
# Claude Code Reviewer — Manual Trigger
# Usage:
#   bash scripts/review.sh          # Review last commit
#   bash scripts/review.sh <SHA>    # Review a specific commit
#   bash scripts/review.sh HEAD~3   # Review 3 commits ago

set -euo pipefail

REVIEW_DIR=".reviews"
PROMPT_FILE=".claude/review-prompt.md"
CLAUDE_CMD="claude"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# ─── Resolve Target Commit ───────────────────────────────
TARGET="${1:-HEAD}"
COMMIT_SHA=$(git rev-parse "$TARGET" 2>/dev/null) || {
    echo -e "${RED}✖ Invalid commit reference: $TARGET${NC}"
    exit 1
}

COMMIT_SHORT=$(git rev-parse --short "$COMMIT_SHA")
COMMIT_MSG=$(git log -1 --pretty=%B "$COMMIT_SHA")
COMMIT_AUTHOR=$(git log -1 --pretty=%an "$COMMIT_SHA")
COMMIT_DATE=$(git log -1 --pretty=%ci "$COMMIT_SHA")
FILES_CHANGED=$(git diff-tree --no-commit-id --name-only -r "$COMMIT_SHA" | head -20)

# ─── Preflight ───────────────────────────────────────────
if ! command -v "$CLAUDE_CMD" &>/dev/null; then
    echo -e "${RED}✖ Claude CLI not found. Install it first: https://docs.anthropic.com/claude-cli${NC}"
    exit 1
fi

# ─── Get Diff ────────────────────────────────────────────
DIFF=$(git show "$COMMIT_SHA" --format="" 2>/dev/null | head -8000)

if [ -z "$DIFF" ]; then
    echo -e "${YELLOW}⚠ No diff found for commit $COMMIT_SHORT${NC}"
    exit 0
fi

# ─── Build Prompt ────────────────────────────────────────
REVIEW_PROMPT="$(cat "$PROMPT_FILE" 2>/dev/null || echo "Review the following commit for bugs, security issues, and code quality.")"

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

# ─── Run Review ──────────────────────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🔍 Claude Code Reviewer (Manual)       ║${NC}"
echo -e "${CYAN}║   Reviewing commit $COMMIT_SHORT             ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

mkdir -p "$REVIEW_DIR"
REVIEW_FILE="$REVIEW_DIR/${COMMIT_SHORT}.md"

REVIEW_OUTPUT=$(echo "$FULL_PROMPT" | $CLAUDE_CMD --print 2>&1) || {
    echo -e "${RED}✖ Claude review failed.${NC}"
    exit 1
}

# ─── Save & Display ─────────────────────────────────────
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
