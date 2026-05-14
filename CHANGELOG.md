# Changelog

## [Unreleased]

- fix: replace hardcoded Firebase credentials in `src/services/fb.js` with environment variables; add startup validation for all required `FIREBASE_*` env vars
- fix: add `userId` validation in `getUserProfile` to reject empty/undefined input
- fix: `sendNotification` now logs and re-throws errors instead of swallowing them silently
