---
description: Error handling rules — try/catch, custom error classes, graceful shutdown, structured logging
globs:
  - "src/**/*.js"
  - "src/**/*.ts"
alwaysApply: false
---

# Error Handling Rules

## General Principles
- Never swallow errors silently — always log or re-throw
- Use try/catch for all async operations
- Fail fast — validate early, return early

## Patterns
```javascript
// ✅ Correct pattern
try {
  const result = await riskyOperation();
  return result;
} catch (error) {
  logger.error('Operation failed', { error: error.message, stack: error.stack });
  throw new AppError('Operation failed', 500, error);
}

// ❌ Anti-pattern
try {
  const result = await riskyOperation();
  return result;
} catch (error) {
  // silently ignored
}
```

## Custom Error Classes
- Create an `AppError` base class with `statusCode`, `message`, and `isOperational` properties
- Use specific subclasses: `ValidationError (400)`, `AuthError (401)`, `NotFoundError (404)`
- Distinguish operational errors (expected) from programmer errors (bugs)

## HTTP Error Responses
- Return consistent error JSON:
  ```json
  { "status": "error", "message": "Human-readable message", "code": "ERROR_CODE" }
  ```
- Never expose stack traces or internal details in production responses
- Log full error details server-side for debugging

## Graceful Shutdown
- Handle `SIGTERM` and `SIGINT` signals
- Close database connections, finish in-flight requests, then exit
- Set a shutdown timeout (e.g., 10s) — force exit if exceeded

## Logging
- Use structured logging (JSON format) for production
- Include: timestamp, level, message, request ID, error details
- Log levels: `error` > `warn` > `info` > `debug`
