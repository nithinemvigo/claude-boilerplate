#!/bin/bash
# Hook triggered after Claude edits a file

FILES=$@

if [ -z "$FILES" ]; then
  exit 0
fi

for file in $FILES; do
  if [[ "$file" == *.ts ]] || [[ "$file" == *.tsx ]] || [[ "$file" == *.js ]] || [[ "$file" == *.jsx ]]; then
    # Try running prettier if available
    npx prettier --write "$file" 2>/dev/null || true
    # Try running eslint --fix if available
    npx eslint --fix "$file" 2>/dev/null || true
  fi
done

exit 0
