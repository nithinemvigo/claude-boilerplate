Audit project dependencies for security vulnerabilities and outdated packages.

## Instructions
1. Run `npm audit --production` and summarize vulnerabilities by severity
2. Run `npm outdated` and list packages that need updating
3. For each vulnerability:
   - **Package** and **severity** (critical/high/medium/low)
   - **Description** of the vulnerability
   - **Fix** — `npm audit fix` or manual upgrade command
4. For outdated packages:
   - **Current** → **Latest** version
   - **Breaking changes** risk (major version bumps)
5. End with a recommended action plan, ordered by severity
