/**
 * One WhatsApp sender, one account.
 *
 * Copy into the backend repo (D:/Projects/aajaoBackend-render/scripts/) and run
 * it from there — it needs that repo's models and .env.
 *
 *   node scripts/fixUatWhatsAppClash.js            # report only
 *   node scripts/fixUatWhatsAppClash.js --apply    # clear the duplicate
 *
 * WhatsApp identifies a sender by phone number and nothing else, so the bot
 * looks a caller up by that number and narrows by the role the session is in.
 * When two live accounts share a number, the same handset resolves to a
 * different person depending on which role it picked — and prerequisite 11 of
 * the BotPenguin UAT pack asks for the opposite: a Guest sender and a Host
 * sender that stay put for the whole run.
 *
 * 9882498033 is the Guest mapping (user 101). A second live account took it and
 * is flagged HOST, so a Host session on that number resolved to them — and a
 * Host Payout OTP would have been emailed to their inbox rather than the test
 * host's.
 *
 * The number is CLEARED rather than replaced. Inventing a stand-in would put a
 * digit string on somebody's account that may belong to a real person, and this
 * account does not need one: it signs in with an email and a password, holds no
 * listings and has never booked or hosted a stay. user_pnumber is nullable and
 * five live accounts already sit without one.
 *
 * Mobile sign-in stops working for that account. Email sign-in does not.
 */
require('dotenv').config();
const model = require('../models');

const APPLY = process.argv.includes('--apply');
const arg = (name, fallback) => {
  const i = process.argv.indexOf(name);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
};

// The account that KEEPS the number, and the number itself.
const KEEPER = Number(arg('--keeper', 101));
const q = (sql, replacements = {}) =>
  model.sequelize.query(sql, { replacements, type: model.sequelize.QueryTypes.SELECT });

(async () => {
  const [keeper] = await q(
    `SELECT user_id, user_fullName, user_pnumber FROM tbl_users WHERE user_id = :k`,
    { k: KEEPER });
  if (!keeper) { console.error(`No user ${KEEPER}.`); process.exit(1); }

  const phone = String(keeper.user_pnumber || '').trim();
  if (!phone) { console.error(`User ${KEEPER} has no number, so nothing can clash with it.`); process.exit(1); }
  console.log(`Guest mapping: ${phone} -> user ${KEEPER} (${keeper.user_fullName})\n`);

  const holders = await q(
    `SELECT u.user_id, u.user_fullName, u.user_isHost, u.user_isUser, u.added_at,
            c.cred_user_email, c.cred_auth_provider,
            (SELECT COUNT(*) FROM tbl_properties p WHERE p.property_host_id = u.user_id) AS listings,
            (SELECT COUNT(*) FROM tbl_bookings b WHERE b.book_user_id = u.user_id) AS booked,
            (SELECT COUNT(*) FROM tbl_bookings b WHERE b.book_host_id = u.user_id) AS hosted
       FROM tbl_users u LEFT JOIN tbl_user_creds c ON c.cred_user_id = u.user_id
      WHERE u.user_pnumber = :phone AND u.user_isDelete = 0 AND u.user_id <> :k
      ORDER BY u.user_id`, { phone, k: KEEPER });

  if (!holders.length) {
    console.log('No other live account holds it. Nothing to fix.');
    process.exit(0);
  }

  console.log('Also live on that number:');
  console.table(holders);

  // Refuse to quietly strip a number off an account somebody is really using.
  // A dormant duplicate is a data-entry accident; an account with listings or
  // bookings is a person's, and which of two numbers is theirs is not a
  // question a script gets to answer.
  const busy = holders.filter((h) => h.listings > 0 || h.booked > 0 || h.hosted > 0);
  if (busy.length) {
    console.error('\nRefusing: these accounts have listings or bookings —');
    console.error(busy.map((h) => `  user ${h.user_id} (${h.cred_user_email})`).join('\n'));
    console.error('Clearing a number off an account in use is a decision for a person, not a script.');
    process.exit(1);
  }

  // Losing the only way in would be worse than the clash. Every one of these
  // accounts must still have an email to sign in with.
  const stranded = holders.filter((h) => !h.cred_user_email);
  if (stranded.length) {
    console.error('\nRefusing: no email to sign in with on', stranded.map((h) => h.user_id).join(', '));
    process.exit(1);
  }

  if (!APPLY) {
    console.log('\nDry run. Re-run with --apply to clear the number from the account(s) above.');
    console.log('Each keeps its email sign-in; mobile sign-in stops working for it.');
    process.exit(0);
  }

  for (const h of holders) {
    await model.tbl_user.update({ user_pnumber: null }, { where: { user_id: h.user_id } });
    console.log(`\ncleared user ${h.user_id} (${h.cred_user_email})`);
    console.log(`  rollback: UPDATE tbl_users SET user_pnumber = '${phone}' WHERE user_id = ${h.user_id};`);
  }

  const after = await q(
    `SELECT user_id, user_fullName, user_isHost, user_isUser FROM tbl_users
      WHERE user_pnumber = :phone AND user_isDelete = 0`, { phone });
  console.log(`\n${phone} now resolves to:`);
  console.table(after);

  process.exit(0);
})().catch((e) => { console.error('FAILED:', e.message); process.exit(1); });
