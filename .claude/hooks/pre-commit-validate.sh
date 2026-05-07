#!/usr/bin/env bash
# Claude PreToolUse hook — ESLint + Prettier gate for git commits
#
# Fires before every Bash tool call. Exits 0 (allow) immediately for
# anything that isn't a git commit. For commits it runs ESLint then
# Prettier; a non-zero exit (code 2) blocks the tool call and sends
# feedback back to Claude.

set -euo pipefail

# ── Read the JSON payload Claude sends via stdin ──────────────────
INPUT=$(cat)

# Extract the bash command being attempted
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
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   🔍 Pre-Commit Validation               ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── ESLint ────────────────────────────────────────────────────────
echo -e "${CYAN}[1/2] Running ESLint...${NC}"
if ! npx eslint . 2>&1; then
  echo ""
  echo -e "${RED}❌ ESLint failed. Fix the errors above before committing.${NC}"
  echo -e "${YELLOW}   Tip: run 'npm run lint:fix' to auto-fix what's possible.${NC}"
  exit 2
fi
echo -e "${GREEN}✅ ESLint passed${NC}"
echo ""

# ── Prettier ──────────────────────────────────────────────────────
echo -e "${CYAN}[2/2] Running Prettier check...${NC}"
if ! npx prettier --check . 2>&1; then
  echo ""
  echo -e "${RED}❌ Prettier check failed. Some files need formatting.${NC}"
  echo -e "${YELLOW}   Tip: run 'npm run format' to auto-format.${NC}"
  exit 2
fi
echo -e "${GREEN}✅ Prettier passed${NC}"
echo ""

echo -e "${GREEN}✅ All checks passed — proceeding with commit.${NC}"
echo ""
exit 0
