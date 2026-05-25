---
description: Input validation rules — Joi/Zod schemas, sanitization, validation middleware
globs:
  - "src/**/*.js"
  - "src/**/*.ts"
  - "**/*.validation.js"
  - "**/*.validator.js"
alwaysApply: false
---

# Validation Rules

## Principles
- NEVER trust client input — validate every `req.body`, `req.params`, `req.query`
- Validate at the EDGE (middleware) before request reaches the controller
- Use a schema library (Joi or Zod) — never hand-roll validation in controllers

## Schema Location
- Store schemas in `src/validation/<resource>.validation.js`
- One schema file per resource — keep schemas close to their validator middleware

## Joi Pattern

  ```javascript
  // src/validation/user.validation.js
  const Joi = require('joi');

  const userSchema = Joi.object({
    username: Joi.string().alphanum().min(3).max(30).required(),
    email: Joi.string().email().required(),
    password: Joi.string().min(8).max(30).required(),
  });

  exports.validateUser = (req, res, next) => {
    const { error } = userSchema.validate(req.body);
    if (error) {
      return res.status(422).json({
        status: 'error',
        message: error.details[0].message,
      });
    }
    next();
  };
  ```

## Rules
- Return `422 Unprocessable Entity` for validation failures (not `400`)
- Return only the first error message — don't leak full schema internals
- Use `.strip()` or `stripUnknown: true` to drop unexpected fields
- Validate types AND constraints (length, format, range)
- For file uploads: validate MIME type, size, and extension separately
- Sanitize HTML/markdown input with `sanitize-html` or DOMPurify before storage