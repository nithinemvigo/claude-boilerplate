---
description: Testing rules — Jest, Supertest, coverage, structure
globs:
  - "**/*.test.js"
  - "**/*.test.ts"
  - "**/*.spec.js"
  - "tests/**/*"
alwaysApply: false
---

# Testing Rules

## Framework
- Use `Jest` as test runner and `Supertest` for HTTP integration tests
- Co-locate tests: `foo.js` → `foo.test.js`
- Run with `npm test`; coverage with `npm run test:coverage` (target ≥ 80%)

## Structure
- Use `describe` blocks per resource/module, `it` per behavior
- Use `beforeAll` / `afterAll` for setup/teardown of DB connections
- Use `afterEach` to clean DB state between tests — never rely on test order

  ```javascript
  beforeAll(async () => { await mongoose.connect(mongoURI); });
  afterEach(async () => { await User.deleteMany({}); });
  afterAll(async () => { await mongoose.connection.close(); });
  ```

## Integration Tests
- Import `app.js` (NOT `server.js`) — never start a real listener in tests
- Use `request(app)` from Supertest to hit endpoints directly
- Assert both `statusCode` and response body shape

  ```javascript
  const res = await request(app)
    .post('/api/v1/users')
    .send({ username: 'test', email: 't@e.com', password: 'pass1234' });
  expect(res.statusCode).toEqual(201);
  expect(res.body).toHaveProperty('username', 'test');
  ```

## Unit Tests
- Test services and utils in isolation — mock external dependencies (DB, HTTP)
- Avoid hitting the real DB or network in unit tests

## Rules
- Tests MUST be deterministic — no time-based flakiness, no random data without seeding
- Run `--detectOpenHandles` to catch leaked connections
- A failing test must NEVER be skipped to ship — fix it or revert the change