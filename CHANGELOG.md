# Changelog

## [Unreleased]

- feat: add private admin API `POST /api/admin/users` — creates admin accounts via x-admin-key auth; adds `src/routes/admin.js`, `src/middleware/adminAuth.js`, and `createAdminUser()` service function

- fix: replace hardcoded Firebase credentials in `src/services/fb.js` with environment variables; add startup validation for all required `FIREBASE_*` env vars
- fix: add `userId` validation in `getUserProfile` to reject empty/undefined input
- fix: `sendNotification` now logs and re-throws errors instead of swallowing them silently
