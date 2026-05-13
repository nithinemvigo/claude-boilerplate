# Testing Rules

## Framework & Tooling
- Jest for unit and integration tests
- Supertest for HTTP endpoint testing
- Test files: `*.test.js` co-located with source files

## Naming & Structure
```javascript
describe('ModuleName', () => {
  describe('functionName', () => {
    it('should return X when given Y', () => { ... });
    it('should throw when input is invalid', () => { ... });
  });
});
```
- Use descriptive `it()` strings that read like specifications
- Group related tests in nested `describe()` blocks

## Coverage
- Target: 80%+ line coverage
- Run: `npm run test:coverage`
- Critical paths (auth, payments, data mutations) must have 100% coverage

## Test Isolation
- Each test must be independent — no shared mutable state between tests
- Use `beforeEach` / `afterEach` for setup/teardown
- Mock external services (HTTP calls, filesystem, database) — never hit real services in tests
- Reset mocks between tests: `jest.clearAllMocks()` in `afterEach`

## What to Test
- ✅ Happy path — expected inputs produce expected outputs
- ✅ Edge cases — empty input, null, undefined, boundary values
- ✅ Error cases — invalid input, network failures, timeouts
- ✅ Security paths — unauthorized access returns 401/403
- ❌ Don't test framework internals or third-party library code

## Async Testing
```javascript
// ✅ Always await async tests
it('should fetch data', async () => {
  const result = await fetchData();
  expect(result).toBeDefined();
});

// ✅ Test async errors
it('should reject on failure', async () => {
  await expect(fetchBadData()).rejects.toThrow('Not found');
});
```
