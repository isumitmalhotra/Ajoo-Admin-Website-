// Prove the key migration puts existing ticks on the checks they were
// actually recorded against — not one row down from where the user left them.
const fs = require("fs");
const vm = require("vm");

function dataOf(file) {
  const src = fs.readFileSync(file, "utf8");
  const m = src.match(/const DATA = \[[\s\S]*?\n\];/);
  const ctx = { module: {}, exports: {} };
  vm.createContext(ctx);
  vm.runInContext(m[0] + "\nglobalThis.__d = DATA;", ctx);
  return ctx.__d;
}

const OLD = dataOf("host-checklist.bak.html");
const NEW = dataOf("host-checklist.html");

// A saved state as it would look after someone worked partway down the list:
// a few in section 0, a couple deep in the wizard section (index 2), one in
// the last section — which is exactly where insertions shifted things.
const picks = [[0, 0], [0, 3], [1, 2], [2, 1], [2, 12], [2, 18], [11, 0]];
const before = {};
for (const [si, ii] of picks) {
  before[si + "|" + ii] = { v: "pass", n: OLD[si].t + " / " + OLD[si].items[ii][0] };
}

// Run the page's own migration against it.
const page = fs.readFileSync("host-checklist.html", "utf8");
// \r? — Python wrote the file on Windows, so the line ends CRLF.
const legacy = page.match(/const LEGACY_KEYS=(\{[\s\S]*?\});\r?\n/)[1];
const sandbox = { state: JSON.parse(JSON.stringify(before)), save() {}, DATA: NEW };
vm.createContext(sandbox);
vm.runInContext(
  "const LEGACY_KEYS=" + legacy + ";" +
  "(function(){let moved=0;for(const k of Object.keys(state)){if(!k.includes('|'))continue;" +
  "const to=LEGACY_KEYS[k];if(to&&state[to]===undefined){state[to]=state[k];moved++;}delete state[k];}" +
  "globalThis.__moved=moved;})();" +
  "globalThis.__id=(s,i)=>DATA[s].t+'::'+DATA[s].items[i][0];",
  sandbox
);

console.log("keys migrated:", sandbox.__moved, "of", picks.length);

// Now read them back the way the page does, and check each tick still names
// the same check it was recorded against.
let ok = 0, bad = 0;
for (const [si, ii] of picks) {
  const wanted = OLD[si].t + " / " + OLD[si].items[ii][0];
  // Find where that check lives in the NEW data.
  let found = null;
  NEW.forEach((sec, s) => sec.items.forEach((it, i) => {
    if (sec.t === OLD[si].t && it[0] === OLD[si].items[ii][0]) found = [s, i];
  }));
  // `continue`, not `return`: this is a CommonJS module, so a top-level
  // return quietly ends the whole script and the summary never prints.
  if (!found) { console.log("  gone from the checklist:", wanted); continue; }
  const st = sandbox.state[sandbox.__id(found[0], found[1])];
  if (st && st.n === wanted) { ok++; }
  else { console.log("  WRONG:", wanted, "->", st ? st.n : "(no tick)"); bad++; }
}
console.log("landed correctly:", ok, " misplaced:", bad);

// And confirm nothing is left under a positional key.
const leftover = Object.keys(sandbox.state).filter((k) => k.includes("|"));
console.log("leftover positional keys:", leftover.length);
process.exitCode = bad || leftover.length ? 1 : 0;
