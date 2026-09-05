/**
 * The eleven development records the BotPenguin UAT pack asks Sumit for.
 *
 * Audits them, and with --apply creates the ones that are missing.
 *
 * Copy this into the backend repo (D:/Projects/aajaoBackend-render/scripts/)
 * and run it from there — it needs that repo's models and .env:
 *
 *   node scripts/seedBotPenguinUatRecords.js            # audit only
 *   node scripts/seedBotPenguinUatRecords.js --apply    # create what is missing
 *
 * Bookings are created through POST /booking/create rather than by INSERT.
 * A booking is not one row: it is tbl_bookings, tbl_book_details,
 * tbl_book_histories, a payment row, a snapshotted cancellation policy and a
 * host-dues entry, behind an availability check. Hand-written rows drift from
 * that within one release, and a test record that is not shaped like a real one
 * tests nothing. So --apply needs a guest login:
 *
 *   UAT_GUEST_EMAIL=... UAT_GUEST_PASSWORD=... node scripts/... --apply
 *
 * Nothing here deletes or overwrites. Every write is additive, and the two
 * bookings it creates are pay-at-property, so no money moves.
 *
 * What it deliberately does NOT do: change anybody's phone number. Prerequisite
 * 11 asks for a stable Guest/Host WhatsApp mapping, and when two live accounts
 * share a number the fix is a decision about whose number it is, not a script's
 * to make.
 */
require('dotenv').config();
const model = require('../models');

const APPLY = process.argv.includes('--apply');
const arg = (name, fallback) => {
  const i = process.argv.indexOf(name);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
};

const BASE = process.env.UAT_API_BASE || 'https://aajaodev.onrender.com';
const GUEST_ID = Number(arg('--guest', 101));
const HOST_ID = Number(arg('--host', 100));
// Which account becomes the Guest+Host one. 169 is the recommendation: it has
// real listings, its inbox receives mail, and its number is not one of the two
// WhatsApp mappings. Overridable, because this is the client's call.
const DUAL_ID = Number(arg('--dual', 169));
// Pay-at-property so the disposable booking can be cancelled without a refund
// to unwind. Host 100's, the listing the existing BPTEST rows already use.
const PROPERTY_ID = Number(arg('--property', 7));

const CANCELLED = 2;
const q = (sql, replacements = {}) =>
  model.sequelize.query(sql, { replacements, type: model.sequelize.QueryTypes.SELECT });

const dd = (d) => String(d.getDate()).padStart(2, '0');
const mm = (d) => String(d.getMonth() + 1).padStart(2, '0');
const fmt = (d) => `${dd(d)}-${mm(d)}-${d.getFullYear()}`;
const addDays = (d, n) => new Date(d.getFullYear(), d.getMonth(), d.getDate() + n);

const say = (n, verdict, detail) =>
  console.log(`${verdict === 'OK' ? ' ok ' : ' GAP'} #${String(n).padStart(2)}  ${detail}`);

const post = async (path, body, token) => {
  const res = await fetch(BASE + path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  try { return { status: res.status, json: JSON.parse(text) }; }
  catch { return { status: res.status, text: text.slice(0, 300) }; }
};

(async () => {
  console.log(`BotPenguin UAT prerequisites — ${BASE}`);
  console.log(APPLY ? 'APPLY: missing records will be created.\n' : 'Audit only. Re-run with --apply to create what is missing.\n');

  const gaps = [];

  // 3 — a Guest with at least two non-cancelled bookings.
  const [multi] = await q(
    `SELECT COUNT(*) n FROM tbl_bookings
      WHERE book_user_id = :g AND book_is_delete = 0 AND book_status <> :c`,
    { g: GUEST_ID, c: CANCELLED });
  say(3, multi.n >= 2 ? 'OK' : 'GAP', `guest ${GUEST_ID} has ${multi.n} non-cancelled bookings`);

  // 4 — a Guest with a stay in progress. Dates are DD-MM-YYYY strings, so every
  // comparison goes through STR_TO_DATE; compared as text they sort by day.
  const ongoing = await q(
    `SELECT b.book_id, d.bt_book_from, d.bt_book_to FROM tbl_bookings b
       JOIN tbl_book_details d ON d.bt_book_pri_id = b.book_pri_id
      WHERE b.book_user_id = :g AND b.book_is_delete = 0 AND b.book_status <> :c
        AND STR_TO_DATE(d.bt_book_from, '%d-%m-%Y') <= CURDATE()
        AND STR_TO_DATE(d.bt_book_to,   '%d-%m-%Y') >= CURDATE()`,
    { g: GUEST_ID, c: CANCELLED });
  say(4, ongoing.length ? 'OK' : 'GAP',
    ongoing.length ? `ongoing stay ${ongoing[0].book_id} (${ongoing[0].bt_book_from} to ${ongoing[0].bt_book_to})`
                   : `guest ${GUEST_ID} has no stay in progress today`);
  if (!ongoing.length) gaps.push('ongoing');

  // 5 — a Host with listings, analytics and payouts.
  const [hostRow] = await q(
    `SELECT (SELECT COUNT(*) FROM tbl_properties WHERE property_host_id = :h) listings,
            (SELECT COUNT(*) FROM tbl_bookings   WHERE book_host_id     = :h) bookings`,
    { h: HOST_ID });
  say(5, hostRow.listings > 0 ? 'OK' : 'GAP',
    `host ${HOST_ID}: ${hostRow.listings} listings, ${hostRow.bookings} bookings`);

  // 6 — one account that is both. Not a new signup: the platform already
  // supports this through POST /user/switch-mode, which mints a token for the
  // other role and always allows the switch back to guest. What is missing is
  // an account whose flags say it holds both, so the guest-side lookups match.
  const both = await q(
    `SELECT u.user_id, u.user_fullName FROM tbl_users u
       JOIN tbl_user_creds c ON c.cred_user_id = u.user_id
      WHERE u.user_isDelete = 0 AND c.cred_user_isDelete = 0
        AND u.user_isHost = 1 AND u.user_isUser = 1`);
  say(6, both.length ? 'OK' : 'GAP',
    both.length ? `dual-role: ${both.map((b) => `${b.user_id} ${b.user_fullName}`).join(', ')}`
                : `no account holds both roles (would set them on user ${DUAL_ID})`);
  if (!both.length) gaps.push('dual');

  // 7 — a booking owned by somebody else, for the ownership-denial test.
  const others = await q(
    `SELECT book_id, book_user_id FROM tbl_bookings
      WHERE book_is_delete = 0 AND book_status <> :c AND book_user_id <> :g
      ORDER BY book_pri_id DESC LIMIT 1`, { g: GUEST_ID, c: CANCELLED });
  say(7, others.length ? 'OK' : 'GAP',
    others.length ? `${others[0].book_id} belongs to user ${others[0].book_user_id}` : 'none found');

  // 8 — a second Host, for the cross-host denial test. Must not be the dual-role
  // account, or the two tests are reading the same record.
  const hosts = await q(
    `SELECT property_host_id id, COUNT(*) n FROM tbl_properties
      WHERE property_host_id NOT IN (:h, :d) GROUP BY property_host_id
      ORDER BY n DESC LIMIT 3`, { h: HOST_ID, d: DUAL_ID });
  say(8, hosts.length ? 'OK' : 'GAP',
    hosts.length ? `second hosts available: ${hosts.map((x) => `${x.id} (${x.n})`).join(', ')}` : 'none');

  // 9 — a disposable booking. Future and non-cancelled, so cancelling it once
  // is a real cancellation and cancelling it twice is a real repeat.
  const disposable = await q(
    `SELECT b.book_id, d.bt_book_from FROM tbl_bookings b
       JOIN tbl_book_details d ON d.bt_book_pri_id = b.book_pri_id
      WHERE b.book_user_id = :g AND b.book_is_delete = 0 AND b.book_status <> :c
        AND STR_TO_DATE(d.bt_book_from, '%d-%m-%Y') > CURDATE()
      ORDER BY STR_TO_DATE(d.bt_book_from, '%d-%m-%Y') ASC`, { g: GUEST_ID, c: CANCELLED });
  say(9, disposable.length ? 'OK' : 'GAP',
    disposable.length ? `${disposable.length} future booking(s), earliest ${disposable[0].book_id} on ${disposable[0].bt_book_from}`
                      : 'no future non-cancelled booking to spend');
  // A dedicated one is created regardless, so UAT-16/17 never has to spend a
  // booking another case is counting on.
  gaps.push('disposable');

  // 10 — where the OTPs land. One sendOtp for every otp_action, addressed to
  // the resolved account's cred_user_email; there is no separate payout inbox.
  const inboxes = await q(
    `SELECT cred_user_id, cred_user_email FROM tbl_user_creds
      WHERE cred_user_id IN (:g, :h)`, { g: GUEST_ID, h: HOST_ID });
  say(10, inboxes.length === 2 ? 'OK' : 'GAP',
    inboxes.map((r) => `${r.cred_user_id === GUEST_ID ? 'guest' : 'host'} OTP -> ${r.cred_user_email}`).join('; '));

  // 11 — the WhatsApp mapping, and whether it is unambiguous. WhatsApp knows
  // only the sender's number, so a number on two live accounts resolves to
  // whichever the role filter happens to pick.
  const numbers = await q(
    `SELECT user_id, user_pnumber, user_isHost, user_isUser
       FROM tbl_users
      WHERE user_pnumber IN (SELECT user_pnumber FROM tbl_users WHERE user_id IN (:g, :h))
        AND user_isDelete = 0
      ORDER BY user_pnumber, user_id`, { g: GUEST_ID, h: HOST_ID });
  const byNumber = new Map();
  for (const r of numbers) {
    if (!byNumber.has(r.user_pnumber)) byNumber.set(r.user_pnumber, []);
    byNumber.get(r.user_pnumber).push(r);
  }
  let ambiguous = false;
  for (const [num, rows] of byNumber) {
    if (rows.length > 1) {
      ambiguous = true;
      say(11, 'GAP', `${num} is on ${rows.length} live accounts: ${rows.map((r) => `${r.user_id}${r.user_isHost ? ' host' : ''}${r.user_isUser ? ' guest' : ''}`).join(', ')}`);
    }
  }
  if (!ambiguous) say(11, 'OK', [...byNumber.keys()].join(' / ') + ' each resolve to one account');

  if (!APPLY) {
    console.log('\nDry run. Re-run with --apply to create the missing records.');
    process.exit(0);
  }

  console.log('\n--- applying ---');

  // 6 — set both flags. cred_user_isHost is left alone deliberately: the login
  // tab filters on it, so flipping it would break host sign-in for this
  // account. The supported route into guest mode is /user/switch-mode.
  if (gaps.includes('dual')) {
    const [before] = await q(
      `SELECT u.user_id, u.user_fullName, u.user_isHost, u.user_isUser,
              c.cred_user_isHost, c.cred_user_isUser
         FROM tbl_users u JOIN tbl_user_creds c ON c.cred_user_id = u.user_id
        WHERE u.user_id = :d`, { d: DUAL_ID });
    if (!before) {
      console.log(`skip dual-role: no user ${DUAL_ID}`);
    } else if (!Number(before.user_isHost)) {
      console.log(`skip dual-role: user ${DUAL_ID} is not a host, so granting guest access proves nothing`);
    } else {
      console.log('BEFORE:', before);
      await model.tbl_user.update({ user_isUser: 1 }, { where: { user_id: DUAL_ID } });
      await model.tbl_user_cred.update({ cred_user_isUser: 1 }, { where: { cred_user_id: DUAL_ID } });
      console.log('AFTER: ', (await q(
        `SELECT u.user_id, u.user_isHost, u.user_isUser, c.cred_user_isHost, c.cred_user_isUser
           FROM tbl_users u JOIN tbl_user_creds c ON c.cred_user_id = u.user_id
          WHERE u.user_id = :d`, { d: DUAL_ID }))[0]);
      console.log(`  rollback: UPDATE tbl_users SET user_isUser = 0 WHERE user_id = ${DUAL_ID};`);
      console.log(`            UPDATE tbl_user_creds SET cred_user_isUser = 0 WHERE cred_user_id = ${DUAL_ID};`);
    }
  }

  // 4 and 9 — through the API, so the records are the shape the product makes.
  const email = process.env.UAT_GUEST_EMAIL;
  const password = process.env.UAT_GUEST_PASSWORD;
  if (!email || !password) {
    console.log('\nSet UAT_GUEST_EMAIL and UAT_GUEST_PASSWORD to create the two bookings.');
    process.exit(0);
  }

  const login = await post('/user/login', { user_email: email, user_password: password });
  const token = login.json?.data?.token;
  if (!token) { console.error('login failed:', login.json?.message || login.status); process.exit(1); }

  const today = new Date();
  const wanted = [
    // Starts YESTERDAY, not today. The bot calls a stay ongoing only once the
    // check-in moment has passed, and that is 2 PM on the arrival day
    // (CHECK_IN_HOUR in utils/chatbotServices.js) — a booking created this
    // morning for today would still read as 'upcoming' until the afternoon.
    { need: 'ongoing', label: '#4 stay in progress', from: addDays(today, -1), nights: 3 },
    { need: 'disposable', label: '#9 disposable booking', from: addDays(today, 14), nights: 2 },
  ].filter((w) => gaps.includes(w.need));

  for (const w of wanted) {
    const bookFrom = fmt(w.from);
    const bookTo = fmt(addDays(w.from, w.nights));
    const r = await post('/booking/create', {
      propertyId: PROPERTY_ID, price: 2100, bookFrom, bookTo, isCod: true, no_of_guests: 2,
    }, token);
    const d = r.json?.data || {};
    console.log(`\n${w.label}  ${bookFrom} -> ${bookTo}`);
    console.log('  ', r.status, r.json?.success, r.json?.message || r.text || '');
    if (d.book_id || d.bookId) console.log('   booking:', d.book_id || d.bookId);
  }

  process.exit(0);
})().catch((e) => { console.error('FAILED:', e.message); process.exit(1); });
