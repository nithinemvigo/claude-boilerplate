Firebase is the BaaS — Auth + Firestore + Storage (+ optionally Functions). Client init lives in `src/lib/firebase.ts`. Security rules in `firestore.rules` and `storage.rules` at the project root — **these are the source of truth for authorization**, not application code. See `.claude/rules/firebase.md`.

For SSR (Next.js): use the Web SDK on the client and verify ID tokens with the Admin SDK on the server. Never bundle `firebase-admin` into the client.
