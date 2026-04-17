#!/bin/bash
# Before EVERY commit: type check → lint → test
# If anything fails, commit is BLOCKED.

echo "Running pre-commit checks..."

# Run TypeScript check if tsc is available
if npx --no tsc -v > /dev/null 2>&1; then
    npx tsc --noEmit || { echo "TypeScript check failed"; exit 1; }
fi

# Get staged TypeScript and JavaScript files
STAGED_FILES=$(git diff --cached --name-only | grep -E "\.(ts|tsx|js|jsx)$")

if [ -n "$STAGED_FILES" ]; then
    # Run ESLint on staged files if eslint is available
    if npx --no eslint -v > /dev/null 2>&1; then
        npx eslint $STAGED_FILES --quiet || { echo "ESLint failed"; exit 1; }
    fi
fi

# Run tests if test script exists in package.json
if grep -q '"test":' package.json 2>/dev/null; then
    npm test -- --passWithNoTests 2>/dev/null || npm test || { echo "Tests failed"; exit 1; }
fi

echo "All checks passed!"
exit 0
