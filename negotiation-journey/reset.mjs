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

// The notifications those offers sent.
//
// Left behind on 2026-09-09, and it cost an hour: the host's Negotiations
// tab was empty while their bell held 23 notices about offers on the same
// listing, which read exactly like a broken screen. It was not — this
// script had deleted the offers between screenshots and nothing had told
// the notifications. A cleanup that removes a record but not the messages
// pointing at it does not undo the test, it fakes a bug.
//
// Titles, not a category column: tbl_user_notification has none, which is
// also why the host feed derives the category from the words.
const NEGOTIATION_TITLES = [
  "The guest countered back",
  "Offer accepted automatically",
  "We answered an offer for you",
  "Your counter was accepted",
  "New price offer",
];

if (!SHOW_ONLY) {
  await db.query(`DELETE FROM tbl_negotiation_offers WHERE property_id = ${PROPERTY}`);
  await db.query(`DELETE FROM tbl_coupons WHERE cpn_property_id = ${PROPERTY} AND cpn_code LIKE 'DEAL%'`);
  const titles = NEGOTIATION_TITLES.map((t) => `'${t.replace(/'/g, "''")}'`).join(", ");
  const [n] = await db.query(
    // PLURAL. The model is tbl_user_notification and Sequelize pluralises it
    // when no tableName is given, so the physical table is …notifications —
    // the singular name throws ER_NO_SUCH_TABLE, which this script would have
    // done on its first real run.
    `DELETE FROM tbl_user_notifications
      WHERE un_propId = ${PROPERTY} AND un_title IN (${titles})`
  );
  await db.query(`DELETE FROM tbl_negotiation_log WHERE nl_property_id = ${PROPERTY}`);
  console.log("  cleared — offers, deal coupons, ledger rows and their notifications.");
}

await db.close();
