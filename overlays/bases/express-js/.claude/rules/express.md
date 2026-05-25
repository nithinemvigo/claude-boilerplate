---
description: Express.js rules — folder structure, controllers, routes, middleware, error handling
globs:
  - "src/**/*.js"
  - "src/**/*.ts"
  - "**/*.controller.js"
  - "**/*.route.js"
  - "**/*.middleware.js"
alwaysApply: true
---

# Express.js Rules

## Folder Structure
- Use a modular, layered structure — never a monolithic `server.js`
  ```
  src/
  ├── config/          ← env vars, DB connection
  ├── controllers/     ← request handlers, orchestrate services
  ├── models/          ← schemas, data access
  ├── routes/          ← endpoint definitions only
  ├── middlewares/     ← reusable Express middleware
  ├── services/        ← core business logic
  ├── validation/      ← Joi/Zod schemas
  ├── utils/           ← helpers
  ├── app.js           ← Express app setup
  └── server.js        ← HTTP server start, DB connect, graceful shutdown
  ```
- Always split `app.js` (configures Express) from `server.js` (starts HTTP + DB) — enables testing

## Controllers
- File name: `<resource>.controller.js` — one per resource
- Function name: `<action><Resource>` (e.g., `getUsers`, `createUser`)
- ALWAYS use `async/await` — never `.then()` chains or callbacks
- Wrap async handlers with `express-async-handler` to avoid repetitive try/catch
- Controllers MUST NOT contain DB queries — delegate to services
- Controllers MUST NOT define routes
- Throw errors (or call `next(err)`) — let centralized error middleware respond

  ```javascript
  // ✅ Good
  const asyncHandler = require('express-async-handler');
  const userService = require('../services/userService');

  exports.getUser = asyncHandler(async (req, res) => {
    const user = await userService.findById(req.params.id);
    if (!user) {
      res.status(404);
      throw new Error('User not found');
    }
    res.status(200).json(user);
  });
  ```

## Routes
- File name: `<resource>.routes.js` — use `express.Router()`
- Routes define endpoints ONLY — no logic, no DB calls
- Middleware order on each route: `validate → auth → controller`
- Follow REST conventions (see `api.md` for full table)

  ```javascript
  // ✅ Good
  const router = require('express').Router();
  router.get('/', auth, getUsers);
  router.post('/', validateUser, createUser);
  router.get('/:id', auth, getUser);
  module.exports = router;
  ```

## Middleware
- File name: `<purpose>.middleware.js`
- Signature: `(req, res, next)` — or `(err, req, res, next)` for error handlers
- Always call `next()` on success or `next(err)` on failure — never both send a response AND call `next()`
- Single responsibility per middleware
- Error-handling middleware MUST be registered LAST in `app.js` with 4 params

## Error Handling
- Centralize all errors via `notFound` + `errorHandler` middleware
- NEVER expose `err.stack` in production responses
- Use custom error classes for typed errors:
  ```javascript
  class AppError extends Error {
    constructor(message, statusCode) {
      super(message);
      this.statusCode = statusCode;
    }
  }
  ```

## Security Middleware (mandatory in `app.js`)
- `helmet()` — secure HTTP headers
- `cors({ origin: process.env.CORS_ORIGIN })` — never wildcard in prod
- `express-rate-limit` — on all public endpoints
- `compression()` — gzip responses
- `express.json({ limit: '1mb' })` — cap body size

## Environment & Config
- All secrets via `.env` — load with `dotenv`, expose through `config/config.js`
- Never hardcode secrets, never fallback like `process.env.X || 'dev-secret'`
- Commit `.env.example`, NEVER commit `.env`

## Cookies
- Always set: `httpOnly: true`, `secure: NODE_ENV === 'production'`, `sameSite: 'Strict'`