Generate or update tests for $ARGUMENTS.

## Instructions
1. Read the target file and its existing test file (if any)
2. Study existing test patterns in `src/**/*.test.js` for style consistency
3. Generate tests covering:
   - Happy path for each exported function/endpoint
   - Error/edge cases (invalid input, null, empty, boundary values)
   - Async error handling (rejected promises, thrown errors)
4. Use Jest (`describe`, `it`, `expect`) and supertest for HTTP endpoints
5. Mock external dependencies (fs, network, database) — never hit real services
6. Name tests descriptively: `it('should return 404 when resource not found')`
7. Run `npm test` after writing to confirm all tests pass
