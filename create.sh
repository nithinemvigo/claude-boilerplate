#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# create.sh  —  friendly shorthand for scripts/apply.sh
#
# Usage:
#   bash create.sh <base> <project-name-or-path> [integrations...] [--dry] [--force]
#   bash create.sh list
#
# Examples:
#   bash create.sh express-js my-api
#   bash create.sh express-js my-api firebase prisma
#   bash create.sh nextjs-ts ../apps/my-next-app tailwind supabase
#   bash create.sh express-js my-api firebase --dry
#   bash create.sh list
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY="${SCRIPT_DIR}/scripts/apply.sh"

# Colors
if [ -t 1 ]; then
  CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
else
  CYAN=''; BOLD=''; DIM=''; RESET=''
fi

print_usage() {
  echo ""
  printf "${BOLD}${CYAN}Claude Boilerplate Creator${RESET}\n"
  echo ""
  echo "  Usage:"
  printf "    ${BOLD}bash create.sh <base> <project-dir> [integrations...] [--dry] [--force]${RESET}\n"
  printf "    ${BOLD}bash create.sh list${RESET}\n"
  echo ""
  echo "  Examples:"
  printf "    ${DIM}bash create.sh express-js my-api${RESET}\n"
  printf "    ${DIM}bash create.sh express-js my-api firebase prisma${RESET}\n"
  printf "    ${DIM}bash create.sh nextjs-ts ../apps/dashboard tailwind supabase${RESET}\n"
  printf "    ${DIM}bash create.sh express-js my-api --dry${RESET}\n"
  printf "    ${DIM}bash create.sh list${RESET}\n"
  echo ""
  echo "  Available bases:"
  bash "${APPLY}" --list 2>/dev/null | grep '  •' || echo "    (run 'bash create.sh list' to see all)"
  echo ""
}

if [ $# -eq 0 ]; then
  print_usage; exit 1
fi

# list shorthand
if [ "$1" = "list" ]; then
  bash "${APPLY}" --list
  exit $?
fi

if [ $# -lt 2 ]; then
  print_usage
  echo "Error: You must provide both a <base> and a <project-dir>."
  exit 1
fi

BASE="$1"
TARGET="$2"
shift 2

# Separate integrations from flags
INTEGRATIONS_ARR=()
PASSTHROUGH_FLAGS=()
for arg in "$@"; do
  case "$arg" in
    --dry|--force) PASSTHROUGH_FLAGS+=("$arg") ;;
    --*) echo "Unknown flag: $arg"; print_usage; exit 1 ;;
    *) INTEGRATIONS_ARR+=("$arg") ;;
  esac
done

# Build apply.sh call
APPLY_ARGS=(--base="${BASE}")
if [ ${#INTEGRATIONS_ARR[@]} -gt 0 ]; then
  INTEGRATIONS_STR=$(printf '%s,' "${INTEGRATIONS_ARR[@]}" | sed 's/,$//')
  APPLY_ARGS+=(--integrations="${INTEGRATIONS_STR}")
fi
APPLY_ARGS+=("${PASSTHROUGH_FLAGS[@]+"${PASSTHROUGH_FLAGS[@]}"}")
APPLY_ARGS+=("${TARGET}")

echo ""
printf "${CYAN}${BOLD}→ bash scripts/apply.sh ${APPLY_ARGS[*]}${RESET}\n"
echo ""

bash "${APPLY}" "${APPLY_ARGS[@]}"
