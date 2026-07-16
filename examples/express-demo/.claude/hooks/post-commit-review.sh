#!/usr/bin/env bash
# Claude PostToolUse hook — save commit record after a successful git commit
#
# The full code review already ran in PreToolUse (pre-commit-validate.sh).
# This hook saves a lightweight commit record to .reviews/ for traceability.

set -euo pipefail

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | python3 -c \
  "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" \
  2>/dev/null || echo "")

if ! echo "$COMMAND" | grep -qE '(^|&&[[:space:]]*|;[[:space:]]*)git commit'; then
  exit 0
fi

REVIEW_DIR=".reviews"
GREEN='\033[0;32m'
NC='\033[0m'

COMMIT_SHA=$(git rev-parse HEAD 2>/dev/null) || exit 0
COMMIT_SHORT=$(git rev-parse --short HEAD)
COMMIT_MSG=$(git log -1 --pretty=%B)
COMMIT_AUTHOR=$(git log -1 --pretty=%an)
COMMIT_DATE=$(git log -1 --pretty=%ci)
FILES_CHANGED=$(git diff-tree --no-commit-id --name-only -r HEAD | head -20)

mkdir -p "$REVIEW_DIR"
RECORD_FILE="$REVIEW_DIR/${COMMIT_SHORT}.md"

{
  echo "# Commit Record — \`$COMMIT_SHORT\`"
  echo ""
  echo "| Field | Value |"
  echo "|-------|-------|"
  echo "| **Commit** | \`$COMMIT_SHA\` |"
  echo "| **Author** | $COMMIT_AUTHOR |"
  echo "| **Date** | $COMMIT_DATE |"
  echo "| **Message** | $COMMIT_MSG |"
  echo "| **Status** | ✅ Passed pre-commit review |"
  echo ""
  echo "### Files Changed"
  echo "$FILES_CHANGED"
} > "$RECORD_FILE"

echo -e "${GREEN}✅ Commit record saved to ${RECORD_FILE}${NC}"
exit 0
