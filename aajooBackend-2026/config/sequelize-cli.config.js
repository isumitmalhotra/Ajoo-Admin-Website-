'use strict';
/**
 * Sequelize CLI connection config — bridges the migration tool to the SAME
 * database the running app uses (config/db.config.js → the live Clever Cloud
 * "cc production" DB), instead of the stale config/config.json `development`
 * block which points at a different, unused DB.
 *
 * Why this exists:
 *   - The RUNNING APP reads its DB connection from config/db.config.js.
 *   - `sequelize-cli` (the migration tool) reads from config/config.json by default.
 *   - Those two pointed at DIFFERENT databases, so `db:migrate` would have
 *     created tables in the wrong place. This file makes the CLI read db.config.js,
 *     so migrations land in the live DB the app actually queries.
 *
 * Activated by .sequelizerc (same folder root). Runtime app is unaffected —
 * this only changes where the CLI connects.
 */
const db = require('./db.config');

const connection = {
  username: db.username,
  password: db.password,
  database: db.database,
  host: db.host,
  port: db.port,
  dialect: db.dialect || 'mysql',
  logging: false,
  // Clever Cloud managed MySQL connects WITHOUT SSL (matches the running app).
  // If you ever hit an SSL handshake / "self signed certificate" error when
  // running migrations, uncomment the block below:
  // dialectOptions: { ssl: { require: true, rejectUnauthorized: false } },
};

// All envs map to the one live DB. There is effectively a single real database
// in play; config.json's separate `development` DB is stale/unreachable.
module.exports = {
  development: connection,
  test: connection,
  production: connection,
};
