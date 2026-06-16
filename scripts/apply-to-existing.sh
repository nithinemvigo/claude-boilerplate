#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# apply-to-existing.sh — drop the Claude Boilerplate into an EXISTING repo.
#
# Unlike `apply.sh`, this script assumes the target already has its own files
# (package.json, .gitignore, eslint config, source code) and you don't want
# any of them clobbered. It:
#
#   1. Stages a full apply.sh in a temp dir.
#   2. Copies files that DON'T exist in the target (.claude/, .agents/, hooks, scripts, rules).
#   3. AUTO-MERGES safe text files (.gitignore, .env.example) — appends unique lines.
#   4. For everything else that collides (package.json, eslint, tsconfig…), prints
#      a per-file merge plan you can act on by hand.
#
# Usage:
#   bash scripts/apply-to-existing.sh --base=<name> [--integrations=a,b] <target>
#   bash scripts/apply-to-existing.sh --preset=<name> <target>
#
# Examples:
#   bash scripts/apply-to-existing.sh --base=express-js ~/work/my-existing-api
#   bash scripts/apply-to-existing.sh --base=nextjs-ts --integrations=supabase,tailwind .
#   bash scripts/apply-to-existing.sh --preset=supabase-nextjs ./my-app
#
# Full contract: docs/apply.html#existing
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY="${SCRIPT_DIR}/apply.sh"

# ── Colors ──────────────────────────────────────────────────────────
if [ -t 1 ]; then
  C_RED='\033[0;31m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[1;33m'
  C_CYAN='\033[0;36m'; C_DIM='\033[2m'; C_BOLD='\033[1m'; C_RESET='\033[0m'
else
  C_RED=''; C_GREEN=''; C_YELLOW=''; C_CYAN=''; C_DIM=''; C_BOLD=''; C_RESET=''
fi

log()     { printf '%b\n' "$*"; }
ok()      { log "  ${C_GREEN}✓${C_RESET}  $*"; }
warn()    { log "  ${C_YELLOW}⚠${C_RESET}  $*"; }
info()    { log "  ${C_CYAN}ℹ${C_RESET}  $*"; }
err()     { log "  ${C_RED}✗${C_RESET}  $*" >&2; }
section() { log ""; log "${C_BOLD}${C_CYAN}— $*${C_RESET}"; }
banner()  {
  log ""
  log "${C_CYAN}${C_BOLD}┌─────────────────────────────────────────────┐${C_RESET}"
  log "${C_CYAN}${C_BOLD}│  🔧  Apply Boilerplate to EXISTING repo      │${C_RESET}"
  log "${C_CYAN}${C_BOLD}└─────────────────────────────────────────────┘${C_RESET}"
}

print_help() {
  cat <<'EOF'
apply-to-existing.sh — apply the Claude Boilerplate to an existing project safely.

USAGE
  bash scripts/apply-to-existing.sh --base=<name> [--integrations=a,b,c] <target>
  bash scripts/apply-to-existing.sh --preset=<name> <target>
  bash scripts/apply-to-existing.sh --help

WHAT IT DOES
  1. Stages a full apply.sh in a temp directory.
  2. Copies files NOT present in the target (.claude/, .agents/, hooks, rules…).
  3. Auto-appends unique lines to .gitignore and .env.example.
  4. Prints a per-file merge plan for files that already exist in the target.

NOTHING IS OVERWRITTEN in the target without your explicit action on the merge plan.

FLAGS (all passed straight through to apply.sh)
  --base=<name>            Required unless --preset is used
  --integrations=<a,b,c>   Optional, comma-separated
  --preset=<name>          Use a preset

EXAMPLES
  bash scripts/apply-to-existing.sh --base=express-js ~/work/my-existing-api
  bash scripts/apply-to-existing.sh --preset=supabase-nextjs ./my-app
EOF
}

# ── Parse args (last positional is the target) ──────────────────────
TARGET=""
APPLY_ARGS=()
for arg in "$@"; do
  case "$arg" in
    -h|--help) print_help; exit 0 ;;
    --base=*|--integrations=*|--preset=*) APPLY_ARGS+=("$arg") ;;
    --*) err "Unknown flag for apply-to-existing.sh: $arg"; print_help; exit 1 ;;
    *) TARGET="$arg" ;;
  esac
done

if [ -z "${TARGET}" ]; then
  err "Target directory is required (last positional argument)."
  print_help; exit 1
fi
if [ ! -d "${TARGET}" ]; then
  err "Target directory does not exist: ${TARGET}"
  err "Use scripts/apply.sh for new projects; this tool is for EXISTING repos."
  exit 1
fi

TARGET="$(cd "${TARGET}" && pwd)"
banner
info "Target:  ${TARGET}"
info "Args:    ${APPLY_ARGS[*]}"

# ── Stage a full apply into a temp dir ──────────────────────────────
STAGE="$(mktemp -d -t boilerplate-existing.XXXXXX)"
trap 'rm -rf "${STAGE}"' EXIT

section "Step 1: stage a full apply"
bash "${APPLY}" "${APPLY_ARGS[@]}" "${STAGE}" > /dev/null
ok "Staged $(find "${STAGE}" -type f | wc -l | tr -d ' ') file(s) in ${STAGE}"

# ── Classify each staged file relative to the target ────────────────
section "Step 2: classify files vs target"

ADDED=()         # new file → copy
IDENTICAL=()     # target already has identical content → skip
CONFLICT=()      # different content → human action needed

while IFS= read -r -d '' staged_file; do
  rel="${staged_file#${STAGE}/}"
  target_file="${TARGET}/${rel}"
  if [ ! -e "${target_file}" ]; then
    ADDED+=("${rel}")
  elif cmp -s "${staged_file}" "${target_file}"; then
    IDENTICAL+=("${rel}")
  else
    CONFLICT+=("${rel}")
  fi
done < <(find "${STAGE}" -type f -print0)

ok "Added (new):    ${#ADDED[@]} file(s)"
ok "Identical:      ${#IDENTICAL[@]} file(s)"
warn "Conflicts:      ${#CONFLICT[@]} file(s)"

# ── Step 3: copy the safe additions ─────────────────────────────────
section "Step 3: copy new files into the target"

for rel in "${ADDED[@]+"${ADDED[@]}"}"; do
  src="${STAGE}/${rel}"
  dst="${TARGET}/${rel}"
  mkdir -p "$(dirname "${dst}")"
  cp -a "${src}" "${dst}"
done
ok "Wrote ${#ADDED[@]} new file(s) into ${TARGET}"

# ── Step 4: auto-merge known-safe text files ────────────────────────
section "Step 4: auto-merge .gitignore and .env.example (if conflicting)"

append_unique_lines() {
  # Append lines from $1 to $2, skipping any line already present in $2.
  # Preserves order; de-dupes silently. Adds a "# from claude-boilerplate" header.
  local source_file="$1" target_file="$2" header="$3"
  local added=0
  local tmp
  tmp="$(mktemp)"
  {
    cat "${target_file}"
    echo ""
    echo "# ─── ${header} (from claude-boilerplate) ───"
    while IFS= read -r line; do
      grep -qxF -- "${line}" "${target_file}" || { echo "${line}"; added=$((added+1)); }
    done < "${source_file}"
  } > "${tmp}"
  if [ "${added}" -gt 0 ]; then
    mv "${tmp}" "${target_file}"
    ok "Appended ${added} new line(s) to ${target_file#${TARGET}/}"
  else
    rm -f "${tmp}"
    info "No new lines to append to ${target_file#${TARGET}/}"
  fi
}

auto_merged=()
REMAINING=()

# .gitignore
if [[ " ${CONFLICT[*]+"${CONFLICT[*]}"} " == *" .gitignore "* ]]; then
  append_unique_lines "${STAGE}/.gitignore" "${TARGET}/.gitignore" "claude-boilerplate"
  auto_merged+=(".gitignore")
fi

# .env.example
if [[ " ${CONFLICT[*]+"${CONFLICT[*]}"} " == *" .env.example "* ]]; then
  append_unique_lines "${STAGE}/.env.example" "${TARGET}/.env.example" "claude-boilerplate integrations"
  auto_merged+=(".env.example")
fi

# Filter the auto-merged ones out of CONFLICT
for rel in "${CONFLICT[@]+"${CONFLICT[@]}"}"; do
  skip=0
  for done_f in "${auto_merged[@]+"${auto_merged[@]}"}"; do
    [ "${rel}" = "${done_f}" ] && skip=1
  done
  [ "${skip}" -eq 0 ] && REMAINING+=("${rel}")
done

# ── Step 5: per-file merge plan for the rest ────────────────────────
section "Step 5: merge plan for files that need human review"

if [ "${#REMAINING[@]}" -eq 0 ]; then
  ok "No further conflicts. Your repo is fully wired."
else
  log ""
  log "  ${C_BOLD}${#REMAINING[@]} file(s)${C_RESET} need a manual merge. Recommended actions:"
  log ""

  printf "  ${C_BOLD}%-32s %s${C_RESET}\n" "FILE" "RECOMMENDED ACTION"
  printf "  ${C_DIM}%-32s %s${C_RESET}\n" "────────────────────────────────" "────────────────────────────────────────"

  for rel in "${REMAINING[@]}"; do
    case "${rel}" in
      package.json)
        printf "  %-32s ${C_YELLOW}DEEP-MERGE${C_RESET}  scripts + devDependencies\n" "${rel}"
        log "       ${C_DIM}diff ${STAGE}/${rel} ${TARGET}/${rel}${C_RESET}"
        log "       ${C_DIM}…then merge \"scripts\" and \"devDependencies\" objects by hand (or via jq)${C_RESET}"
        ;;
      tsconfig.json|tsconfig.recommended.json)
        printf "  %-32s ${C_YELLOW}MERGE${C_RESET}       compilerOptions (theirs wins on conflicts)\n" "${rel}"
        log "       ${C_DIM}diff ${STAGE}/${rel} ${TARGET}/${rel}${C_RESET}"
        ;;
      eslint.config.js|.eslintrc*|*.eslintrc*)
        printf "  %-32s ${C_YELLOW}REVIEW${C_RESET}      keep yours; copy in any rules you like from boilerplate\n" "${rel}"
        log "       ${C_DIM}diff ${STAGE}/${rel} ${TARGET}/${rel}${C_RESET}"
        ;;
      .prettierrc|.prettierignore|.editorconfig|.nvmrc)
        printf "  %-32s ${C_YELLOW}REVIEW${C_RESET}      usually theirs wins; check for inconsistencies\n" "${rel}"
        log "       ${C_DIM}diff ${STAGE}/${rel} ${TARGET}/${rel}${C_RESET}"
        ;;
      CLAUDE.md)
        cp "${STAGE}/${rel}" "${TARGET}/${rel}.boilerplate"
        printf "  %-32s ${C_GREEN}SAVED${C_RESET}       boilerplate version saved as ${rel}.boilerplate\n" "${rel}"
        log "       ${C_DIM}Merge by hand; your existing CLAUDE.md was not touched.${C_RESET}"
        ;;
      *)
        printf "  %-32s ${C_YELLOW}REVIEW${C_RESET}      diff and decide\n" "${rel}"
        log "       ${C_DIM}diff ${STAGE}/${rel} ${TARGET}/${rel}${C_RESET}"
        ;;
    esac
  done
fi

# ── Step 6: copy the staging dir for the user's reference ───────────
KEEP_STAGE="${TARGET}/.claude-boilerplate-staging"
rm -rf "${KEEP_STAGE}"
cp -a "${STAGE}" "${KEEP_STAGE}"
trap - EXIT
rm -rf "${STAGE}"

section "Done"
ok "Added ${#ADDED[@]} new file(s) · auto-merged ${#auto_merged[@]} · ${#REMAINING[@]} need manual review"
log ""
log "${C_BOLD}Boilerplate's full output is preserved at:${C_RESET}"
log "  ${KEEP_STAGE}"
log "${C_DIM}Use it for diffs while you finish merging. Delete the dir when done:${C_RESET}"
log "  ${C_DIM}rm -rf ${KEEP_STAGE}${C_RESET}"
log ""
log "${C_BOLD}Next steps${C_RESET}"
log "  1. Resolve manual-merge items above"
log "  2. Install required Claude Code plugins:"
log "       claude /plugins install https://claude.com/plugins/security-guidance"
log "       claude /plugins install https://claude.com/plugins/code-review"
log "  3. npm install"
log "  4. bash scripts/check-setup.sh   # verify"
log "  5. Add a project-specific section in CLAUDE.md (Architecture, Auth, etc.)"
log "  6. ${C_DIM}rm -rf ${KEEP_STAGE}${C_RESET}"
log ""

exit 0
