/**
 * Wrap a built checklist into a standalone HTML file you can hand to somebody.
 *
 * The published artifacts are private to the owner's account and save answers
 * into themselves. A tester on another machine needs neither — they need one
 * file they can open from their desktop, mark up, and send back. So this emits
 * a complete document (the artifact host supplies the doctype and <head>,
 * which a file on disk has to carry itself), with a short preamble saying how
 * to return findings, and the fonts inlined as a same-origin-free link so it
 * still looks right offline-ish.
 *
 *   node build_standalone.cjs guest   →  dist/Aajoo-Renter-Testing-Guide.html
 *   node build_standalone.cjs host    →  dist/Aajoo-Host-Testing-Guide.html
 *   node build_standalone.cjs admin   →  dist/Aajoo-Admin-Testing-Guide.html
 */
const fs = require("fs");
const path = require("path");

const DOCS = {
  guest: {
    src: "guest-checklist.html",
    out: "Aajoo-Renter-Testing-Guide.html",
    title: "Aajoo — Renter Testing Guide",
    who: "renter (guest) side",
  },
  host: {
    src: "host-checklist.html",
    out: "Aajoo-Host-Testing-Guide.html",
    title: "Aajoo — Host Testing Guide",
    who: "host side",
  },
  admin: {
    src: "admin-checklist.html",
    out: "Aajoo-Admin-Testing-Guide.html",
    title: "Aajoo — Admin Testing Guide",
    who: "admin dashboard",
  },
};

const key = process.argv[2] || "guest";
const doc = DOCS[key];
if (!doc) {
  console.error("Unknown doc %o — expected one of %s", key, Object.keys(DOCS).join(", "));
  process.exit(1);
}

const body = fs.readFileSync(path.join(__dirname, doc.src), "utf8");

// The preamble goes above the checklist's own lede. Testers who were handed a
// copy have no artifact behind them, so the two things they must know are that
// their answers live in THIS browser and that Copy report is how findings come
// back.
const PREAMBLE = `
<div class="handout">
  <strong>How to use this file</strong>
  <p>
    Work down the list in order and mark every check <b>Pass</b>, <b>Fail</b> or
    <b>Blocked</b>. Write what you actually saw in the note box — the exact
    message, the page you were on, what you had typed. A note saying
    “didn’t work” costs another round trip.
  </p>
  <p>
    <b>Your answers are saved in this browser only</b>, in this copy of the
    file. They are not shared with anyone and they will not appear in anyone
    else’s copy. Don’t clear your browser data mid-run, and keep using the same
    browser to pick up where you left off.
  </p>
  <p>
    When you finish — or any time you want the team to look at something —
    press <b>Copy report</b> in the bar at the top. It puts every failure and
    blocker on your clipboard along with your notes, plus a line for every
    check you marked, ready to paste into an email or a chat.
  </p>
  <p class="handout-site">
    Test against <a href="https://www.aajoohomes.com">www.aajoohomes.com</a>.
    Use a test account, never a personal one, and never type a real bank
    account number, card number or IFSC into any form — for payment and bank
    forms, submit the fields empty to check the validation and stop there.
  </p>
</div>
`;

const HANDOUT_CSS = `
  .handout{
    max-width:64ch; margin:0 0 22px; padding:16px 18px;
    background:var(--panel); border:1px solid var(--rule);
    border-left:3px solid var(--accent); border-radius:11px;
    box-shadow:var(--shadow);
  }
  .handout strong{display:block; font-size:14.5px; margin-bottom:8px;}
  .handout p{margin:0 0 9px; font-size:13.6px; line-height:1.6; color:var(--ink-2);}
  .handout p:last-child{margin-bottom:0;}
  .handout b{color:var(--ink); font-weight:600;}
  .handout-site a{color:var(--accent); font-weight:600;}
`;

let out = body;

// 1. The checklist's own <title> becomes the document title in the wrapper, so
//    drop the loose one rather than emitting two.
out = out.replace(/^<title>[^<]*<\/title>\s*/, "");

// 2. Handout styles ride along with the page's own.
out = out.replace("</style>", HANDOUT_CSS + "\n</style>");

// 3. Preamble above the first lede.
const ledeAt = out.indexOf('    <p class="lede">');
if (ledeAt === -1) throw new Error("could not find the lede to place the preamble above");
out = out.slice(0, ledeAt) + PREAMBLE.trim() + "\n" + out.slice(ledeAt);

const page = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${doc.title}</title>
<meta name="description" content="Manual QA checklist for the Aajoo Homes ${doc.who}.">
</head>
<body>
${out}
</body>
</html>
`;

const dir = path.join(__dirname, "dist");
fs.mkdirSync(dir, { recursive: true });
const dest = path.join(dir, doc.out);
fs.writeFileSync(dest, page, "utf8");

const checks = (body.match(/^\s*\["/gm) || []).length;
console.log("%s  —  %d KB, ~%d checks", dest, Math.round(page.length / 1024), checks);
