// Clear the demo negotiation thread between scenarios.
//
// Each scenario in journey.mjs starts a fresh conversation, and the engine
// quite rightly refuses a second offer while one is already pending — so
// without this, scenario 2 would photograph scenario 1's leftovers.
//
// Reaches the backend's own dependencies by absolute path rather than adding a
// script to that repository: this is documentation tooling and has no business
// living in the production codebase.
//
//   node negotiation-journey/reset.mjs            # clears listing 29291
//   node negotiation-journey/reset.mjs --show     # show, do not delete
import { createRequire } from "node:module";

const BACKEND = "D:/Projects/aajaoBackend-render";
const require = createRequire(BACKEND + "/package.json");

require("dotenv").config({ path: BACKEND + "/.env" });
const { Sequelize } = require("sequelize");
const cfg = require(BACKEND + "/config/db.config");

const PROPERTY = Number(process.env.DEMO_PROPERTY || 29291);
const SHOW_ONLY = process.argv.includes("--show");

const db = new Sequelize(cfg.database, cfg.username, cfg.password, {
  host: cfg.host, port: cfg.port, dialect: cfg.dialect || "mysql", logging: false,
});

const [offers] = await db.query(
  `SELECT offer_id, sender_id, offer_price, offer_number, offer_status
     FROM tbl_negotiation_offers WHERE property_id = ${PROPERTY} ORDER BY offer_id`
);
const [coupons] = await db.query(
  `SELECT cpn_id, cpn_code FROM tbl_coupons WHERE cpn_property_id = ${PROPERTY} AND cpn_code LIKE 'DEAL%'`
);

for (const o of offers) {
  console.log(`  #${o.offer_id} round ${o.offer_number} ${o.offer_price} [${o.offer_status}]`);
}
console.log(`  ${offers.length} offer(s), ${coupons.length} deal coupon(s) on listing ${PROPERTY}`);

if (!SHOW_ONLY) {
  await db.query(`DELETE FROM tbl_negotiation_offers WHERE property_id = ${PROPERTY}`);
  await db.query(`DELETE FROM tbl_coupons WHERE cpn_property_id = ${PROPERTY} AND cpn_code LIKE 'DEAL%'`);
  console.log("  cleared.");
}

await db.close();
