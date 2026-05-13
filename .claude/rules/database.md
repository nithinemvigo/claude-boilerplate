# Database Rules

## Connection Management
- Always use connection pooling — never create a new connection per request
- Set connection pool min/max limits and idle timeout
- Close connections gracefully on process shutdown (`SIGTERM`, `SIGINT`)

## Query Safety
- ALWAYS use parameterized queries / prepared statements — never concatenate user input into SQL
  ```javascript
  // ✅ Good
  db.query('SELECT * FROM users WHERE id = $1', [userId]);
  // ❌ Bad
  db.query(`SELECT * FROM users WHERE id = ${userId}`);
  ```
- Use an ORM or query builder (Knex, Prisma, Sequelize) to reduce raw SQL risk

## Migrations
- All schema changes must go through migration files — never modify production DB manually
- Migrations must be reversible (include up + down)
- Name migration files with timestamps: `20240101_create_users_table.js`

## Indexing
- Add indexes on columns used in WHERE, JOIN, and ORDER BY clauses
- Add unique indexes for uniqueness constraints (email, username)
- Avoid over-indexing — each index adds write overhead

## Transactions
- Use transactions for multi-step writes that must be atomic
- Always rollback on error within a transaction
- Keep transactions as short as possible — avoid I/O inside transactions

## Data Validation
- Validate data types and constraints at the application level before hitting the database
- Use database-level constraints as a safety net (NOT NULL, UNIQUE, CHECK)
