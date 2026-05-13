# Security Rules

## Input Sanitization
- Never trust user input — validate, sanitize, and escape all inputs
- Use allowlists over denylists when validating input
- Sanitize for the output context (HTML, SQL, shell, URL)

## Authentication & Authorization
- Use industry-standard auth (JWT, OAuth 2.0, session cookies with httpOnly + secure flags)
- Hash passwords with bcrypt (min cost factor 12) or argon2 — never store plaintext
- Implement proper RBAC — check permissions on every protected endpoint
- Use short-lived access tokens + refresh tokens

## Secrets Management
- NEVER hardcode secrets, API keys, or credentials in source code
- Use environment variables loaded from `.env` (excluded via `.gitignore`)
- Rotate secrets periodically and support secret rotation without redeployment

## Common Vulnerabilities (OWASP)
- **Injection**: Use parameterized queries, never `exec()` with user input
- **XSS**: Escape output rendered in HTML, set `Content-Security-Policy` header
- **CSRF**: Use CSRF tokens for state-changing requests from browsers
- **Path Traversal**: Validate and resolve file paths — reject `../` patterns
- **SSRF**: Validate and whitelist outbound URLs — never fetch arbitrary user-supplied URLs

## HTTP Security Headers
```
Content-Security-Policy: default-src 'self'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-XSS-Protection: 0
Referrer-Policy: strict-origin-when-cross-origin
```

## Dependencies
- Run `npm audit` regularly — fix critical and high vulnerabilities immediately
- Pin dependency versions in `package-lock.json`
- Review new dependencies before adding — check maintenance status and download count
