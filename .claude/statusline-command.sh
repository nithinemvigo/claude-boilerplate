#!/usr/bin/env bash
# Claude Code status line — context · cost · session · git

input=$(cat)

# ── Session ───────────────────────────────────────────────────────
session_id=$(  echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id',''))"   2>/dev/null || echo "")
session_name=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_name',''))" 2>/dev/null || echo "")
model=$(       echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('model',{}).get('display_name',''))" 2>/dev/null || echo "")
cwd=$(         echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cwd',''))"          2>/dev/null || echo "")

if [ -n "$session_name" ]; then
  session_label="$session_name"
elif [ -n "$session_id" ]; then
  session_label="${session_id: -8}"
else
  session_label="--"
fi

# ── Context window ────────────────────────────────────────────────
used_pct=$(echo "$input" | python3 -c "
import sys,json
d=json.load(sys.stdin)
cw=d.get('context_window',{})
print(cw.get('used_percentage',''))
" 2>/dev/null || echo "")

if [ -n "$used_pct" ]; then
  pct=$(printf '%.0f' "$used_pct")
  if   [ "$pct" -ge 90 ] 2>/dev/null; then ctx_str="ctx:${pct}%(!)"
  elif [ "$pct" -ge 75 ] 2>/dev/null; then ctx_str="ctx:${pct}%(~)"
  else ctx_str="ctx:${pct}%"
  fi
else
  ctx_str="ctx:--"
fi

# ── Session tokens (cost proxy) ───────────────────────────────────
total_in=$(  echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('context_window',{}).get('total_input_tokens',0))"  2>/dev/null || echo "0")
total_out=$( echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('context_window',{}).get('total_output_tokens',0))" 2>/dev/null || echo "0")
total_tokens=$(( ${total_in:-0} + ${total_out:-0} ))

if   [ "$total_tokens" -ge 1000000 ] 2>/dev/null; then
  tok_display=$(python3 -c "print(f'{$total_tokens/1000000:.1f}M')")
elif [ "$total_tokens" -ge 1000 ] 2>/dev/null; then
  tok_display=$(python3 -c "print(f'{$total_tokens//1000}k')")
elif [ "$total_tokens" -gt 0 ] 2>/dev/null; then
  tok_display="$total_tokens"
else
  tok_display="0"
fi
cost_str="~${tok_display}tok"

# ── Git branch + status ────────────────────────────────────────────
git_str=""
repo_dir="${cwd:-$(pwd)}"
if git -C "$repo_dir" rev-parse --is-inside-work-tree &>/dev/null; then
  branch=$(git -C "$repo_dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || \
           git -C "$repo_dir" rev-parse --short HEAD 2>/dev/null || echo "HEAD")
  git_status=$(git -C "$repo_dir" --no-optional-locks status --porcelain 2>/dev/null || echo "")
  staged=$(   echo "$git_status" | grep -c '^[MADRC]'  2>/dev/null || echo 0)
  unstaged=$( echo "$git_status" | grep -c '^.[MD]'    2>/dev/null || echo 0)
  untracked=$(echo "$git_status" | grep -c '^??'       2>/dev/null || echo 0)
  flags=""
  [ "${staged:-0}"    -gt 0 ] && flags="${flags}+${staged}"
  [ "${unstaged:-0}"  -gt 0 ] && flags="${flags}${flags:+ }~${unstaged}"
  [ "${untracked:-0}" -gt 0 ] && flags="${flags}${flags:+ }?${untracked}"
  if [ -n "$flags" ]; then
    git_str="git:${branch} [${flags}]"
  else
    git_str="git:${branch} ✓"
  fi
fi

# ── Rate limits (Claude.ai subscribers) ───────────────────────────
rate_str=""
five_pct=$(echo "$input" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(d.get('rate_limits',{}).get('five_hour',{}).get('used_percentage',''))
" 2>/dev/null || echo "")
week_pct=$(echo "$input" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(d.get('rate_limits',{}).get('seven_day',{}).get('used_percentage',''))
" 2>/dev/null || echo "")
[ -n "$five_pct" ] && rate_str="5h:$(printf '%.0f' "$five_pct")%"
[ -n "$week_pct" ] && rate_str="${rate_str:+${rate_str} }7d:$(printf '%.0f' "$week_pct")%"

# ── Assemble ──────────────────────────────────────────────────────
parts=()
parts+=("◈ ${session_label}")
[ -n "$model" ] && parts+=("$model")
parts+=("$ctx_str")
parts+=("$cost_str")
[ -n "$git_str"  ] && parts+=("$git_str")
[ -n "$rate_str" ] && parts+=("$rate_str")

# Join with separator
result="${parts[0]}"
for part in "${parts[@]:1}"; do
  result="${result}  ·  ${part}"
done
printf '%s\n' "$result"
