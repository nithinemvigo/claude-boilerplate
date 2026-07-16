---
description: Environment variable rules — never hardcode secrets, always use process.env with validation
globs:
  - "**/*.js"
  - "**/*.ts"
  - "**/*.env*"
  - ".env.example"
alwaysApply: true
---

# Environment Configuration Rules

## Environment Variables
- All configuration MUST come from environment variables via `process.env`
- Never hardcode secrets, URLs, ports, or credentials in source code
- Reference `.env.example` as the template for required variables

## .env Files
- `.env` — local development (gitignored, never committed)
- `.env.example` — template with placeholder values (committed to repo)
- `.env.test` — test environment overrides (optional, gitignored)

## Access Pattern
```javascript
// ✅ Good — with defaults for development
const PORT = process.env.PORT || 3000;
const DB_URL = process.env.DATABASE_URL; // required, no default

// ✅ Good — validate required vars at startup
const requiredVars = ['DATABASE_URL', 'API_SECRET'];
for (const v of requiredVars) {
  if (!process.env[v]) {
    throw new Error(`Missing required environment variable: ${v}`);
  }
}

// ❌ Bad — hardcoded values
const DB_PASSWORD = 'admin123';
```

## Naming Conventions
- Use SCREAMING_SNAKE_CASE: `DATABASE_URL`, `API_SECRET`, `NODE_ENV`
- Prefix app-specific vars: `APP_PORT`, `APP_LOG_LEVEL`
- Standard vars: `NODE_ENV`, `PORT`, `LOG_LEVEL`

## Security
- .env files must be in `.gitignore`
- Rotate secrets without code changes — use environment variable updates
- In CI/CD, use platform secret management (GitHub Secrets, Bitbucket Variables)
