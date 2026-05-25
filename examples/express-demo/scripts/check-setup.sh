#!/usr/bin/env bash
# check-setup.sh — verify the target project is ready for the Claude Boilerplate pipeline.
#
# Usage:
#   bash scripts/check-setup.sh
#   npm run check-setup
#
# Exits 0 if every check passes, 1 if any check fails.
# Run after `apply.sh`, after installing deps, and any time the dev env changes.

set -uo pipefail

# ── Colors ──────────────────────────────────────────────────────────
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  CYAN='\033[0;36m'; DIM='\033[2m'; BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; CYAN=''; DIM=''; BOLD=''; NC=''
fi

PASS=0
FAIL=0
WARN=0

check_pass() { printf "  ${GREEN}✓${NC}  %s\n" "$1"; PASS=$((PASS+1)); }
check_fail() { printf "  ${RED}✗${NC}  %s\n     ${DIM}↳ %s${NC}\n" "$1" "$2"; FAIL=$((FAIL+1)); }
check_warn() { printf "  ${YELLOW}⚠${NC}  %s\n     ${DIM}↳ %s${NC}\n" "$1" "$2"; WARN=$((WARN+1)); }

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

echo ""
echo -e "${CYAN}${BOLD}┌─────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}${BOLD}│  🔧  Claude Boilerplate — Setup Check       │${NC}"
echo -e "${CYAN}${BOLD}└─────────────────────────────────────────────┘${NC}"
echo ""

# ── Node version ────────────────────────────────────────────────────
echo -e "${BOLD}Runtime${NC}"
if command -v node >/dev/null 2>&1; then
  NODE_V="$(node -v 2>/dev/null | sed 's/^v//')"
  if [ -f ".nvmrc" ]; then
    EXPECTED="$(tr -d '[:space:]v' < .nvmrc)"
    if [ "${NODE_V%%.*}" = "${EXPECTED%%.*}" ]; then
      check_pass "Node ${NODE_V} matches .nvmrc (${EXPECTED})"
    else
      check_warn "Node ${NODE_V} but .nvmrc requests ${EXPECTED}" \
                 "Run: nvm use   (or install via 'nvm install ${EXPECTED}')"
    fi
  else
    check_pass "Node ${NODE_V} installed (no .nvmrc to check against)"
  fi
else
  check_fail "node not found on PATH" "Install Node from https://nodejs.org"
fi

# ── npm ─────────────────────────────────────────────────────────────
if command -v npm >/dev/null 2>&1; then
  check_pass "npm $(npm -v) installed"
else
  check_fail "npm not found on PATH" "Comes with Node — reinstall Node"
fi

# ── Claude CLI ──────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Claude Code${NC}"
if command -v claude >/dev/null 2>&1; then
  check_pass "claude CLI on PATH"
else
  check_fail "claude CLI not found" \
             "Install: https://docs.anthropic.com/claude-cli"
fi

# ── Plugins ─────────────────────────────────────────────────────────
PROBE=".claude/hooks/plugin-probe.sh"
if [ -x "$PROBE" ]; then
  for plugin in security-guidance code-review; do
    if bash "$PROBE" "$plugin" >/dev/null 2>&1; then
      check_pass "Plugin '${plugin}' installed"
    else
      check_fail "Plugin '${plugin}' NOT installed" \
                 "Install: claude /plugins install https://claude.com/plugins/${plugin}"
    fi
  done
else
  check_warn "plugin-probe.sh missing — can't verify plugins" \
             "Re-run scripts/apply.sh to restore .claude/hooks/"
fi

# ── Hook wiring ─────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Hooks${NC}"
if [ -f ".claude/settings.json" ]; then
  if grep -q "pre-commit-validate.sh" .claude/settings.json; then
    check_pass "Pre-commit hook wired in .claude/settings.json"
  else
    check_warn ".claude/settings.json exists but pre-commit hook not referenced" \
               "Compare against core/.claude/settings.json in the boilerplate"
  fi
else
  check_fail ".claude/settings.json not found" \
             "Re-run scripts/apply.sh to restore"
fi

if [ -x ".claude/hooks/pre-commit-validate.sh" ]; then
  check_pass "pre-commit-validate.sh is executable"
elif [ -f ".claude/hooks/pre-commit-validate.sh" ]; then
  check_warn "pre-commit-validate.sh found but not executable" \
             "Run: chmod +x .claude/hooks/pre-commit-validate.sh"
else
  check_fail ".claude/hooks/pre-commit-validate.sh missing" \
             "Re-run scripts/apply.sh to restore"
fi

# ── Environment ─────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Environment${NC}"
if [ -f ".env" ]; then
  check_pass ".env exists"
elif [ -f ".env.example" ]; then
  check_warn ".env not created yet" \
             "Copy: cp .env.example .env   then fill in real values"
else
  check_warn "No .env or .env.example" "Each integration ships keys; re-run apply.sh if needed"
fi

if [ -d "node_modules" ]; then
  check_pass "node_modules present (deps installed)"
else
  check_warn "node_modules missing" "Run: npm install"
fi

# ── Summary ─────────────────────────────────────────────────────────
echo ""
echo -e "${DIM}────────────────────────────────────────────${NC}"
TOTAL=$((PASS + FAIL + WARN))
printf "  ${BOLD}%d checks${NC}  " "$TOTAL"
[ "$PASS" -gt 0 ] && printf "${GREEN}● %d pass${NC}  " "$PASS" || printf "${DIM}● 0 pass${NC}  "
[ "$WARN" -gt 0 ] && printf "${YELLOW}● %d warn${NC}  " "$WARN" || printf "${DIM}● 0 warn${NC}  "
[ "$FAIL" -gt 0 ] && printf "${RED}● %d fail${NC}\n" "$FAIL" || printf "${DIM}● 0 fail${NC}\n"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo -e "${RED}${BOLD}Setup incomplete.${NC} Address the ✗ items above, then re-run."
  echo ""
  exit 1
fi

if [ "$WARN" -gt 0 ]; then
  echo -e "${YELLOW}Setup OK with warnings.${NC} Address the ⚠ items for a fully wired environment."
  echo ""
  exit 0
fi

echo -e "${GREEN}${BOLD}All checks passed.${NC} You're ready to commit."
echo ""
exit 0
