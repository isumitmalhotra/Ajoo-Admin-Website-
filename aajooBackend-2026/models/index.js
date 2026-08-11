'use strict';

const fs = require('fs');
const path = require('path');
const Sequelize = require('sequelize');
const basename = path.basename(__filename);
const env = process.env.NODE_ENV || 'development';
const dbConfig = require("../config/db.config");
const logger = require('../utils/logger');
const config = require(__dirname + '/../config/config.json')[env];

const db = {};
let sequelize;

// // ------------------ Live Database -------------------
// sequelize = new Sequelize({
//   username: dbConfig.username,
//   password: dbConfig.password,
//   database: dbConfig.database,
//   host: dbConfig.host,
//   port: dbConfig.port,
//   dialect: dbConfig.dialect,
//   logging: dbConfig.logging, 
//   dialectOptions: {
//     ssl: {
//       require: true,               // ✅ important
//       rejectUnauthorized: false    // ✅ accept self-signed certs
//     }
//   },

//   pool: {
//     max: 5,       // must not exceed MySQL max_user_connections (your host = 5)
//     min: 0,
//     acquire: 30000, // try 30s before throwing "Connection Timeout"
//     idle: 10000    // release idle connections after 10s
//   }
// });

// // ------------------ Local Database (optional) -------------------
if (config.use_env_variable) {
  sequelize = new Sequelize(process.env[config.use_env_variable], config);
} else {
  sequelize = new Sequelize(config.database, config.username, config.password, config);
}

// // ------------------ Test Connection -------------------
// sequelize.authenticate()
//   .then(() => {
//     console.log('✅ Database connection established successfully.');
//   })
//   .catch(err => {
//     console.error('❌ Unable to connect to the database:', err.message);
//   });

// ------------------ Load Models -------------------
fs.readdirSync(__dirname)
  .filter(file =>
    file.indexOf('.') !== 0 &&
    file !== basename &&
    file.slice(-3) === '.js' &&
    file.indexOf('.test.js') === -1
  )
  .forEach(file => {
    const model = require(path.join(__dirname, file))(sequelize, Sequelize.DataTypes);
    db[model.name] = model;
  });

// ------------------ Run Associations -------------------
Object.keys(db).forEach(modelName => {
  if (db[modelName].associate) {
    db[modelName].associate(db);
  }
});

db.sequelize = sequelize;
db.Sequelize = Sequelize;

// ------------------ Graceful Shutdown -------------------
process.on('SIGINT', async () => {
  logger.info('SIGINT signal received: closing database connection.');
  await sequelize.close();
  logger.info('Database connection closed.');
  process.exit(0);
});

module.exports = db;
