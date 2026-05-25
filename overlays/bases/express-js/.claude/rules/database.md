---
description: Database rules — connection pooling, parameterized queries, migrations, transactions
globs:
  - "src/**/*.js"
  - "src/**/*.ts"
  - "**/*.model.js"
  - "**/*.model.ts"
  - "**/*.repository.js"
alwaysApply: false
---

# Database Rules

## Connection Management
- Always use connection pooling — never create a new connection per request
- Set connection pool min/max limits and idle timeout
- Close connections gracefully on process shutdown (`SIGTERM`, `SIGINT`)
- Connection logic lives in `src/config/db.js` — called once from `server.js`

## Query Safety
- ALWAYS use parameterized queries / prepared statements — never concatenate user input into SQL
  ```javascript
  // ✅ Good
  db.query('SELECT * FROM users WHERE id = $1', [userId]);
  // ❌ Bad
  db.query(`SELECT * FROM users WHERE id = ${userId}`);
  ```
- Use an ORM or query builder (Knex, Prisma, Sequelize, Mongoose) to reduce raw SQL risk
- Repository pattern: DB access lives in `src/models/` or `src/repositories/`, never in controllers

## Migrations
- All schema changes must go through migration files — never modify production DB manually
- Migrations must be reversible (include `up` + `down`)
- Name migration files with timestamps: `20240101_create_users_table.js`
- Migrations run in CI before deploy — never on app boot

## Indexing
- Add indexes on columns used in WHERE, JOIN, and ORDER BY clauses
- Add unique indexes for uniqueness constraints (email, username)
- Avoid over-indexing — each index adds write overhead

## Transactions
- Use transactions for multi-step writes that must be atomic
- Always rollback on error within a transaction
- Keep transactions as short as possible — avoid I/O (HTTP, queue) inside transactions

  ```javascript
  // ✅ Good
  const trx = await db.transaction();
  try {
    await trx('orders').insert(order);
    await trx('inventory').decrement('stock', 1).where({ id: order.itemId });
    await trx.commit();
  } catch (err) {
    await trx.rollback();
    throw err;
  }
  ```

## Data Validation
- Validate data types and constraints at the application level before hitting the database
- Use database-level constraints as a safety net (NOT NULL, UNIQUE, CHECK)

## Sensitive Data
- Never log full query results containing PII or credentials
- Hash passwords before insert — never store plaintext
- Encrypt sensitive columns at rest (tokens, API keys) when supported