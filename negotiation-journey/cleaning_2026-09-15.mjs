/**
 * Photographs for §8a31 — the cleaning fee is stated, not charged.
 *
 * 29310 (₹12,000 a night, ₹1,000 cleaning): the price card with the
 * statement under the total and Things to know with the line; then the
 * review page reached through Book Now, where the same sentence sits under
 * Total Amount and the price sent is the room + party + pets.
 *
 *   node cleaning_2026-09-15.mjs
 */
import { open, shot, dismissBanners, pause, SITE } from "./rig.mjs";

const today = new Date();
const plus = (n) => { const d = new Date(today); d.setDate(d.getDate() + n); return d; };
const dmy = (d) => `${String(d.getDate()).padStart(2, "0")}-${String(d.getMonth() + 1).padStart(2, "0")}-${d.getFullYear()}`;

async function clipAround(page, text, { up = 8, down = 8, wide = 300 } = {}) {
  return page.evaluate((t, up, down, wide) => {
    const n = [...document.querySelectorAll("span,div,h3,strong,p")].find((e) => (e.innerText || "").trim() === t && e.getBoundingClientRect().width < 260);
    let node = n; for (let i = 0; i < 8 && node?.parentElement; i += 1) { node = node.parentElement; if (node.getBoundingClientRect().width > wide) break; }
    const r = node?.getBoundingClientRect(); if (!r) return null;
    return { x: r.x - up + scrollX, y: r.y - up + scrollY, width: r.width + up * 2, height: Math.min(1100, r.height + up + down) };
  }, text, up, down, wide);
}

const { browser, page } = await open("renter", { headless: true });
try {
  const iso = (d) => d.toISOString().slice(0, 10);
  const from = iso(plus(2)), to = iso(plus(4));
  await page.goto(`${SITE}/property?id=29310&from=${from}&to=${to}`, { waitUntil: "domcontentloaded" });
  await pause(9000);
  await dismissBanners(page);

  const card = await clipAround(page, "Total");
  await shot(page, "s31-29310-card", card ? { clip: card } : {});
  const cardText = await page.evaluate(() => document.body.innerText);
  const hasStatement = /The host charges ₹1,000 for cleaning if you ask for it/.test(cardText);
  const hasLine = /Cleaning fee/.test(cardText);
  const hasRule = /Cleaning available at ₹1,000 per stay, paid to the host/.test(cardText);
  const total = (cardText.match(/Total\s*\n?\s*(₹[\d,]+(?:\.\d+)?)/) || [])[1];
  console.log(`  card: total=${total} statement=${hasStatement} cleaningLine=${hasLine} thingsToKnow=${hasRule}`);

  const ttk = await clipAround(page, "Things to know", { wide: 600, down: 40 });
  await shot(page, "s31-29310-things-to-know", ttk ? { clip: ttk } : {});

  // Book Now → review page.
  const h = await page.evaluateHandle(() => [...document.querySelectorAll("button")].find((b) => /^Book Now/i.test((b.innerText || "").trim())) || null);
  const el = h.asElement();
  if (el) {
    await el.scrollIntoView(); await pause(300); await el.click(); await pause(8000);
    console.log(`  url: ${page.url()}`);
    const rv = await page.evaluate(() => document.body.innerText);
    const rvTotal = (rv.match(/Total Amount\s*\n?\s*(₹[\d,]+(?:\.\d+)?)/) || [])[1];
    console.log(`  review: total=${rvTotal} statement=${/for cleaning if you ask for it/.test(rv)} cleaningLine=${/Cleaning fee/.test(rv)}`);
    const rc = await clipAround(page, "Total Amount", { wide: 300, down: 90 });
    await shot(page, "s31-29310-review", rc ? { clip: rc } : {});
  } else {
    console.log("  no Book Now button (signed out, or the dates are not free)");
  }
} finally {
  await browser.close();
}
