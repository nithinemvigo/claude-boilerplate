#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# apply.sh — the Claude Boilerplate composer.
#
# Composes a target project from:
#   1. core/                              (always)
#   2. overlays/bases/<base>/             (exactly one)
#   3. overlays/integrations/<name>/...   (zero or more, in order)
#
# Usage:
#   bash scripts/apply.sh --base=<name> [--integrations=a,b] [opts] <target>
#   bash scripts/apply.sh --preset=<name> [opts] <target>
#   bash scripts/apply.sh --list
#   bash scripts/apply.sh --help
#
# Full contract: docs/apply.html
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Constants ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CORE_DIR="${REPO_ROOT}/core"
BASES_DIR="${REPO_ROOT}/overlays/bases"
INTEGRATIONS_DIR="${REPO_ROOT}/overlays/integrations"
PRESETS_DIR="${REPO_ROOT}/presets"

EXIT_OK=0
EXIT_USAGE=1
EXIT_COMBO=2
EXIT_CONFLICT=3
EXIT_NOT_FOUND=4

# ── Colors (only on a tty) ───────────────────────────────────────────────────
if [ -t 1 ]; then
  C_RED='\033[0;31m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[1;33m'
  C_CYAN='\033[0;36m'; C_DIM='\033[2m'; C_BOLD='\033[1m'; C_RESET='\033[0m'
else
  C_RED=''; C_GREEN=''; C_YELLOW=''; C_CYAN=''; C_DIM=''; C_BOLD=''; C_RESET=''
fi

log()      { printf '%b\n' "$*"; }
info()     { log "${C_CYAN}ℹ${C_RESET}  $*"; }
ok()       { log "${C_GREEN}✓${C_RESET}  $*"; }
warn()     { log "${C_YELLOW}⚠${C_RESET}  $*" >&2; }
err()      { log "${C_RED}✗${C_RESET}  $*" >&2; }
section()  { log ""; log "${C_BOLD}${C_CYAN}— $*${C_RESET}"; }

# ── Built-in compatibility map (bash 3-compatible — no associative arrays) ───
# Returns the allowed integrations for a given base name.
compat_for() {
  case "$1" in
    express-js)     echo "supabase firebase prisma trpc zod" ;;
    express-ts)     echo "supabase firebase prisma trpc zod" ;;
    nestjs)         echo "supabase firebase prisma trpc zod" ;;
    react-vite-ts)  echo "supabase firebase tailwind tanstack-query zod" ;;
    nextjs-ts)      echo "supabase firebase tailwind prisma trpc nextauth tanstack-query zod" ;;
    node-js)        echo "prisma zod" ;;
    node-ts)        echo "prisma zod" ;;
    react-js)       echo "supabase firebase tailwind tanstack-query" ;;
    react-ts)       echo "supabase firebase tailwind tanstack-query zod" ;;
    nextjs-js)      echo "supabase firebase tailwind prisma trpc nextauth tanstack-query" ;;
    *)              echo "" ;;
  esac
}

# Bases where supabase/firebase are unusual (soft warning):
SOFT_WARN_BASES=("node-js" "node-ts")

# ── Argument parsing ─────────────────────────────────────────────────────────
BASE=""
INTEGRATIONS=""
PRESET=""
TARGET=""
DRY=0
FORCE=0
LIST=0

print_help() {
  cat <<'EOF'
apply.sh — the Claude Boilerplate composer.

USAGE
  bash scripts/apply.sh --base=<name> [--integrations=a,b,c] [options] <target-dir>
  bash scripts/apply.sh --preset=<name> [options] <target-dir>
  bash scripts/apply.sh --list
  bash scripts/apply.sh --help

OPTIONS
  --base=<name>            One of the base names in overlays/bases/
  --integrations=<a,b,c>   Comma-separated. Order determines CLAUDE.md Architecture order.
  --preset=<name>          Use a preset from presets/<name>.json (mutually exclusive
                           with --base/--integrations).
  --target=<path>          Target directory (or pass it as the last positional arg).
  --dry                    Plan-only mode. Nothing is written to disk.
  --force                  Bypass soft warnings. Hard errors are never bypassable.
  --list                   Show available bases, integrations, and presets.
  -h, --help               This message.

EXAMPLES
  bash scripts/apply.sh --base=nextjs-ts --integrations=supabase,tailwind ../my-app
  bash scripts/apply.sh --preset=t3-stack ../my-app
  bash scripts/apply.sh --base=express-ts --integrations=prisma --dry /tmp/scratch

DOCS
  Full contract:        docs/apply.html
  Compatibility matrix: docs/integrations/index.html
EOF
}

for arg in "$@"; do
  case "$arg" in
    --base=*)         BASE="${arg#*=}" ;;
    --integrations=*) INTEGRATIONS="${arg#*=}" ;;
    --preset=*)       PRESET="${arg#*=}" ;;
    --target=*)       TARGET="${arg#*=}" ;;
    --dry)            DRY=1 ;;
    --force)          FORCE=1 ;;
    --list)           LIST=1 ;;
    -h|--help)        print_help; exit ${EXIT_OK} ;;
    --*)              err "Unknown flag: ${arg}"; print_help; exit ${EXIT_USAGE} ;;
    *)                TARGET="${arg}" ;;
  esac
done

# ── Helpers ──────────────────────────────────────────────────────────────────

python_or_die() {
  if ! command -v python3 >/dev/null 2>&1; then
    err "python3 is required (used for JSON merging and preset reading)."
    exit ${EXIT_USAGE}
  fi
}

# Read a key from a JSON file. Returns empty if missing.
json_get() {
  local file="$1" key="$2"
  python3 -c "
import json, sys
try:
    d = json.load(open('${file}'))
    v = d.get('${key}')
    if isinstance(v, list): print(','.join(v))
    elif v is None:         print('')
    else:                   print(v)
except Exception as e:
    print('', file=sys.stderr)
"
}

# Deep-merge two JSON objects. Later wins on collision. Prints merged JSON.
json_merge() {
  local base="$1" add="$2"
  python3 - <<PY
import json
def merge(a, b):
    if isinstance(a, dict) and isinstance(b, dict):
        out = dict(a)
        for k, v in b.items():
            out[k] = merge(a.get(k), v) if k in a else v
        return out
    return b
a = json.load(open("${base}")) if "${base}" else {}
b = json.load(open("${add}"))
print(json.dumps(merge(a, b), indent=2))
PY
}

list_bases() {
  if [ ! -d "${BASES_DIR}" ]; then return; fi
  find "${BASES_DIR}" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' 2>/dev/null \
    || ls "${BASES_DIR}"
}

list_integrations() {
  if [ ! -d "${INTEGRATIONS_DIR}" ]; then return; fi
  find "${INTEGRATIONS_DIR}" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' 2>/dev/null \
    || ls "${INTEGRATIONS_DIR}"
}

list_presets() {
  if [ ! -d "${PRESETS_DIR}" ]; then return; fi
  find "${PRESETS_DIR}" -maxdepth 1 -mindepth 1 -name '*.json' -printf '%f\n' 2>/dev/null \
    | sed 's/\.json$//'
}

# ── --list short-circuit ─────────────────────────────────────────────────────
if [ "${LIST}" = "1" ]; then
  log "${C_BOLD}Bases${C_RESET} (overlays/bases/):"
  for b in $(list_bases); do log "  • ${b}"; done
  log ""
  log "${C_BOLD}Integrations${C_RESET} (overlays/integrations/):"
  for i in $(list_integrations); do log "  • ${i}"; done
  log ""
  log "${C_BOLD}Presets${C_RESET} (presets/):"
  for p in $(list_presets); do log "  • ${p}"; done
  log ""
  log "${C_DIM}Use --base=<name> --integrations=<a,b> or --preset=<name> to apply.${C_RESET}"
  exit ${EXIT_OK}
fi

# ── Validate argument combination ────────────────────────────────────────────
if [ -n "${PRESET}" ] && { [ -n "${BASE}" ] || [ -n "${INTEGRATIONS}" ]; }; then
  err "--preset is mutually exclusive with --base/--integrations."
  exit ${EXIT_USAGE}
fi

if [ -z "${PRESET}" ] && [ -z "${BASE}" ]; then
  err "Either --base=<name> or --preset=<name> is required."
  print_help; exit ${EXIT_USAGE}
fi

if [ -z "${TARGET}" ]; then
  err "Target directory is required (positional arg or --target=<path>)."
  exit ${EXIT_USAGE}
fi

# ── Expand preset (if any) ───────────────────────────────────────────────────
if [ -n "${PRESET}" ]; then
  python_or_die
  local_preset_file="${PRESETS_DIR}/${PRESET}.json"
  if [ ! -f "${local_preset_file}" ]; then
    err "Preset not found: ${PRESET} (looked at ${local_preset_file})"
    err "Available presets: $(list_presets | tr '\n' ' ')"
    exit ${EXIT_NOT_FOUND}
  fi
  BASE=$(json_get "${local_preset_file}" "base")
  INTEGRATIONS=$(json_get "${local_preset_file}" "integrations")
  info "Preset '${PRESET}' expands to: --base=${BASE} --integrations=${INTEGRATIONS}"
fi

# ── Validate base exists ─────────────────────────────────────────────────────
BASE_PATH="${BASES_DIR}/${BASE}"
if [ ! -d "${BASE_PATH}" ]; then
  err "Base not found: ${BASE} (looked at ${BASE_PATH})"
  err "Available bases: $(list_bases | tr '\n' ' ')"
  exit ${EXIT_NOT_FOUND}
fi

# ── Validate each integration exists & is compatible ─────────────────────────
INT_ARRAY=()
if [ -n "${INTEGRATIONS}" ]; then
  IFS=',' read -ra INT_ARRAY <<< "${INTEGRATIONS}"
fi

# Build the allowed set for this base.
ALLOWED=""
overlay_compat="${BASE_PATH}/compatible-integrations.txt"
if [ -f "${overlay_compat}" ]; then
  ALLOWED=$(tr '\n' ' ' < "${overlay_compat}")
else
  ALLOWED=$(compat_for "${BASE}")
  if [ -z "${ALLOWED}" ]; then
    warn "Base '${BASE}' has no compatibility declaration. Allowing all integrations — verify manually."
    ALLOWED="ALL"
  fi
fi

is_allowed() {
  local needle="$1"
  [ "${ALLOWED}" = "ALL" ] && return 0
  for x in ${ALLOWED}; do [ "$x" = "${needle}" ] && return 0; done
  return 1
}

is_soft_warn_base() {
  for b in "${SOFT_WARN_BASES[@]}"; do [ "${b}" = "${BASE}" ] && return 0; done
  return 1
}

for integ in "${INT_ARRAY[@]+"${INT_ARRAY[@]}"}" ; do
  [ -z "${integ}" ] && continue
  if [ ! -d "${INTEGRATIONS_DIR}/${integ}" ]; then
    err "Integration not found: ${integ} (looked at ${INTEGRATIONS_DIR}/${integ})"
    err "Available integrations: $(list_integrations | tr '\n' ' ')"
    exit ${EXIT_NOT_FOUND}
  fi
  if ! is_allowed "${integ}"; then
    err "Integration '${integ}' is NOT compatible with base '${BASE}'."
    err "Allowed for ${BASE}: ${ALLOWED}"
    exit ${EXIT_COMBO}
  fi
  # Soft-warn case
  if { [ "${integ}" = "supabase" ] || [ "${integ}" = "firebase" ]; } && is_soft_warn_base; then
    if [ "${FORCE}" = "1" ]; then
      warn "'${integ}' on bare-Node base '${BASE}' is unusual — proceeding because --force."
    else
      warn "'${integ}' on bare-Node base '${BASE}' is unusual. Re-run with --force to proceed."
      exit ${EXIT_COMBO}
    fi
  fi
done

# ── Resolve & prepare target ─────────────────────────────────────────────────
TARGET="$(cd "$(dirname "${TARGET}")" 2>/dev/null && pwd)/$(basename "${TARGET}")" \
  || TARGET="${TARGET}"

if [ ! -d "${TARGET}" ]; then
  if [ "${DRY}" = "1" ]; then
    info "Target '${TARGET}' does not exist. (dry-run — would create it.)"
  else
    info "Target '${TARGET}' does not exist. Creating."
    mkdir -p "${TARGET}"
  fi
fi

# Staging area
STAGE="$(mktemp -d -t claude-boilerplate-apply.XXXXXX)"
trap 'rm -rf "${STAGE}"' EXIT

# ── Step 1: copy core ────────────────────────────────────────────────────────
section "Step 1: copy core/"
if [ -d "${CORE_DIR}" ]; then
  cp -a "${CORE_DIR}/." "${STAGE}/"
  ok "Copied core/ ($(find "${CORE_DIR}" -type f | wc -l | tr -d ' ') files)"
else
  err "core/ not found at ${CORE_DIR}"
  exit ${EXIT_NOT_FOUND}
fi

# ── Step 2: copy base overlay ────────────────────────────────────────────────
section "Step 2: copy base overlay (${BASE})"
# Skip the meta-files that aren't meant to land in the target:
META="compatible-integrations.txt package.scripts.json CLAUDE.fragment.md"
copied=0
while IFS= read -r -d '' f; do
  rel="${f#${BASE_PATH}/}"
  case " ${META} " in *" ${rel} "*) continue ;; esac
  dest="${STAGE}/${rel}"
  mkdir -p "$(dirname "${dest}")"
  cp -a "${f}" "${dest}"
  copied=$((copied+1))
done < <(find "${BASE_PATH}" -type f -print0 2>/dev/null)
ok "Copied ${copied} file(s) from base '${BASE}'"

# ── Step 3: copy each integration (with conflict detection) ──────────────────
INT_META="compatible-with.txt package.snippet.json env.snippet architecture.md"
for integ in "${INT_ARRAY[@]+"${INT_ARRAY[@]}"}" ; do
  [ -z "${integ}" ] && continue
  section "Step 3: integration ${integ}"
  ipath="${INTEGRATIONS_DIR}/${integ}"
  added=0
  while IFS= read -r -d '' f; do
    rel="${f#${ipath}/}"
    [ "${rel}" = ".gitkeep" ] && continue
    case " ${INT_META} " in *" ${rel} "*) continue ;; esac
    dest="${STAGE}/${rel}"
    if [ -e "${dest}" ]; then
      err "Integration '${integ}' would overwrite existing file: ${rel}"
      err "Integrations must be additive. This is a bug in the integration."
      exit ${EXIT_CONFLICT}
    fi
    mkdir -p "$(dirname "${dest}")"
    cp -a "${f}" "${dest}"
    added=$((added+1))
  done < <(find "${ipath}" -type f -print0 2>/dev/null)
  ok "Added ${added} file(s) from integration '${integ}'"
done

# ── Step 4: merge package.json scripts + devDependencies ─────────────────────
section "Step 4: merge package.json"
python_or_die
merged_pkg_tmp="${STAGE}/package.json.merged"
echo '{}' > "${merged_pkg_tmp}"

# If staging already has a package.json (from base or core), start from it.
if [ -f "${STAGE}/package.json" ]; then
  cp "${STAGE}/package.json" "${merged_pkg_tmp}"
fi

merge_sources=()
[ -f "${BASE_PATH}/package.scripts.json" ] && merge_sources+=("${BASE_PATH}/package.scripts.json")
for integ in "${INT_ARRAY[@]+"${INT_ARRAY[@]}"}" ; do
  [ -z "${integ}" ] && continue
  snip="${INTEGRATIONS_DIR}/${integ}/package.snippet.json"
  [ -f "${snip}" ] && merge_sources+=("${snip}")
done

if [ ${#merge_sources[@]} -eq 0 ]; then
  info "No package.scripts.json / package.snippet.json sources — skipping merge."
else
  for src in "${merge_sources[@]}"; do
    json_merge "${merged_pkg_tmp}" "${src}" > "${merged_pkg_tmp}.next"
    mv "${merged_pkg_tmp}.next" "${merged_pkg_tmp}"
    ok "Merged $(basename "$(dirname "${src}")")/$(basename "${src}")"
  done
  mv "${merged_pkg_tmp}" "${STAGE}/package.json"
fi
rm -f "${merged_pkg_tmp}" "${merged_pkg_tmp}.next" 2>/dev/null || true

# ── Step 5: render CLAUDE.md ─────────────────────────────────────────────────
section "Step 5: render CLAUDE.md"
template="${STAGE}/CLAUDE.template.md"
fragment="${BASE_PATH}/CLAUDE.fragment.md"

if [ -f "${template}" ]; then
  out="${STAGE}/CLAUDE.md"
  if [ -f "${fragment}" ]; then
    # Read fragment as a single value and substitute placeholders.
    python3 - <<PY > "${out}"
import re
tpl = open("${template}").read()
frag = open("${fragment}").read()
# Convention: the fragment file is split into named sections by '## {{KEY}}' headers.
# Each section's body replaces the matching {{KEY}} in the template.
sections = {}
current = None
for line in frag.splitlines():
    m = re.match(r"^##\s*\{\{(\w+)\}\}\s*$", line)
    if m:
        current = m.group(1)
        sections[current] = []
        continue
    if current is not None:
        sections[current].append(line)
sections = {k: "\n".join(v).strip() for k, v in sections.items()}
def sub(m):
    return sections.get(m.group(1), m.group(0))
print(re.sub(r"\{\{(\w+)\}\}", sub, tpl))
PY
    ok "Rendered CLAUDE.md from template + base fragment"
  else
    warn "No CLAUDE.fragment.md for base '${BASE}' — copying template as-is."
    cp "${template}" "${out}"
  fi
  # Append each integration's architecture paragraph
  for integ in "${INT_ARRAY[@]+"${INT_ARRAY[@]}"}" ; do
    [ -z "${integ}" ] && continue
    arch="${INTEGRATIONS_DIR}/${integ}/architecture.md"
    if [ -f "${arch}" ]; then
      {
        echo ""
        echo "## Integration: ${integ}"
        echo ""
        cat "${arch}"
      } >> "${out}"
      ok "Appended ${integ}/architecture.md to CLAUDE.md"
    fi
  done
  rm -f "${template}"
else
  warn "No CLAUDE.template.md in core/ — skipping CLAUDE.md render."
fi

# ── Step 6: append .env.example ──────────────────────────────────────────────
section "Step 6: append .env.example"
env_target="${STAGE}/.env.example"
touch "${env_target}"
for integ in "${INT_ARRAY[@]+"${INT_ARRAY[@]}"}" ; do
  [ -z "${integ}" ] && continue
  snip="${INTEGRATIONS_DIR}/${integ}/env.snippet"
  if [ -f "${snip}" ]; then
    {
      echo ""
      echo "# ─── ${integ} ───"
      cat "${snip}"
    } >> "${env_target}"
    ok "Appended env keys for '${integ}'"
  fi
done

# ── Step 7: dry-run vs commit ────────────────────────────────────────────────
if [ "${DRY}" = "1" ]; then
  section "Dry-run summary (no files written to target)"
  staged_files=$(find "${STAGE}" -type f | wc -l | tr -d ' ')
  log "Would write ${staged_files} file(s) to: ${TARGET}"
  log ""
  log "${C_DIM}Sample (first 20):${C_RESET}"
  find "${STAGE}" -type f | head -20 | sed "s|${STAGE}/|  |"
  log ""
  log "${C_DIM}(staging dir cleaned up automatically)${C_RESET}"
  exit ${EXIT_OK}
fi

# Copy staging → target (refuse to clobber unless --force)
section "Step 7: write to target ${TARGET}"
if [ "${FORCE}" != "1" ]; then
  conflicts=()
  while IFS= read -r -d '' f; do
    rel="${f#${STAGE}/}"
    if [ -e "${TARGET}/${rel}" ]; then conflicts+=("${rel}"); fi
  done < <(find "${STAGE}" -type f -print0)
  if [ ${#conflicts[@]} -gt 0 ]; then
    err "Target already has ${#conflicts[@]} file(s) the boilerplate would overwrite:"
    for c in "${conflicts[@]:0:10}"; do err "  - ${c}"; done
    [ ${#conflicts[@]} -gt 10 ] && err "  …and $((${#conflicts[@]} - 10)) more"
    err "Re-run with --force to overwrite, or --dry to preview."
    exit ${EXIT_CONFLICT}
  fi
fi

cp -a "${STAGE}/." "${TARGET}/"
final_count=$(find "${STAGE}" -type f | wc -l | tr -d ' ')

# ── Step 8: summary ──────────────────────────────────────────────────────────
section "Done"
ok "Applied base '${BASE}'$([ -n "${INTEGRATIONS}" ] && echo " + integrations [${INTEGRATIONS}]")"
log "  Files written: ${final_count}"
log "  Target:        ${TARGET}"
log ""
log "${C_BOLD}Next steps${C_RESET}"
log "  1. cd ${TARGET}"
log "  2. npm install"
log "  3. Install required Claude Code plugins (one-time, per machine):"
log "       claude /plugins install https://claude.com/plugins/security-guidance"
log "       claude /plugins install https://claude.com/plugins/code-review"
log "  4. cp .env.example .env  # then fill in real values"
log "  5. Review CLAUDE.md and fill in any project-specific TODOs"
log "  6. npm run check-setup   # verify everything is wired"
log "  7. npm run validate      # lint + format + build + test"
log ""
log "${C_DIM}Plugins:${C_RESET} the pre-commit hook downgrades to a warning if either plugin"
log "${C_DIM}        is missing. Set CLAUDE_BOILERPLATE_STRICT=1 to fail hard instead.${C_RESET}"
log ""
log "${C_DIM}Docs: docs/apply.html · docs/bases/${BASE}.html$(for i in "${INT_ARRAY[@]+"${INT_ARRAY[@]}"}" ; do [ -n "$i" ] && echo -n " · docs/integrations/${i}.html"; done)${C_RESET}"

exit ${EXIT_OK}
