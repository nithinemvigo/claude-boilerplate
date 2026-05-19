---
description: Firebase rules — security rules, listener cleanup, query limits, auth tokens
globs:
  - "**/lib/firebase*"
  - "firestore.rules"
  - "storage.rules"
alwaysApply: false
---

# Firebase Rules

## Security rules are not optional

- `firestore.rules` and `storage.rules` are the source of truth for authorization.
- Default `allow read, write: if false;` stays until you write a real rule.
- Test rules with the Firebase emulator before shipping: `firebase emulators:start --only firestore`.
- The pre-commit `/security-review` hook flags rule files with `allow read, write: if true;`.

## Web SDK vs Admin SDK

- **Web SDK** (`firebase`) — browser. The config (apiKey, projectId, etc.) is public by design.
- **Admin SDK** (`firebase-admin`) — server-only. Has full access. Use the service account JSON, base64-encoded in env.

## Listeners must unsubscribe

```ts
useEffect(() => {
  const unsub = onSnapshot(query(...), handler);
  return unsub;
}, []);
```

Forgetting unsubscribe leaks listeners across renders. Each leak burns reads.

## Always query with limits

```ts
// ✅ Good
const q = query(collection(db, 'todos'), where('userId', '==', uid), limit(50));
// ❌ Bad — unbounded
const q = collection(db, 'todos');
```

Firestore charges per document read. An unlimited query in a busy collection is an outage in a billing slip.

## Auth token freshness

- `getIdToken(true)` forces a refresh — use before calling your backend.
- Token TTL is 1 hour; let the SDK refresh in the background.

## Server-side auth in Next.js

- The Web SDK is browser-only.
- For server-side auth, verify the ID token with the Admin SDK in middleware or a Route Handler.

## Bundle size

- Import individual modules: `import { initializeApp } from 'firebase/app'`.
- Never `import firebase from 'firebase'` — pulls the entire SDK.

## Cold starts

- Initialize the Admin SDK outside your handler so it's reused across invocations.
