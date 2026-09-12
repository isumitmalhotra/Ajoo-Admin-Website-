// One offer, one photograph — the privacy demonstration.
//
// The point of section "why the minimum cannot be found" is that three offers
// a rupee apart, straddling the host's floor, come back with the SAME answer
// in the same words. Each of them has to be round one of its own thread, so
// the negotiation estate is cleared between them:
//
//   node negotiation-journey/probe.mjs 29301 1190 p1-below-floor
//   node scripts/... --clear            (in the backend, between each)
//   node negotiation-journey/probe.mjs 29301 1200 p2-on-floor
//   node negotiation-journey/probe.mjs 29301 1210 p3-above-floor
//
// Deliberately a different listing from the one the rest of the document uses:
// these three photographs exist to be compared with EACH OTHER, and running
// them on the main listing would mean wiping the thread the document is built
// around three times over.
import { open, shot, pause, dismissBanners, SITE } from "./rig.mjs";

const PROPERTY = process.argv[2] || "29301";
const PRICE = process.argv[3] || "1200";
const NAME = process.argv[4] || `probe-${PRICE}`;
const FROM = process.argv[5] || "12-09-2026";
const TO = process.argv[6] || "13-09-2026";

const { browser, page } = await open("renter");
try {
  await page.goto(`${SITE}/property?id=${PROPERTY}&from=${FROM}&to=${TO}&guests=2`, { waitUntil: "domcontentloaded" });
  await pause(7000);
  await dismissBanners(page);
  await pause(600);

  const click = async (text) => {
    const h = await page.evaluateHandle((t) => {
      const want = t.toLowerCase();
      return [...document.querySelectorAll("button")]
        .find((b) => !b.disabled && (b.innerText || "").trim().toLowerCase().startsWith(want)) || null;
    }, text);
    const el = h.asElement();
    if (!el) throw new Error(`no enabled button starting "${text}"`);
    await el.scrollIntoView();
    await pause(350);
    await el.click();
  };

  await click("Send an Offer");
  await pause(1600);

  const h = await page.evaluateHandle(() => {
    const dlg = [...document.querySelectorAll("div")].find((d) => /Your offer per night/i.test(d.textContent || "") && d.querySelector("input"));
    return dlg?.querySelector("input") || document.querySelector('input[inputmode="numeric"]');
  });
  const el = h.asElement();
  if (!el) throw new Error("offer price input not found");
  await el.click({ clickCount: 3 });
  await page.keyboard.press("Backspace");
  await el.type(String(PRICE));
  await pause(400);

  // The three answers are identical by design, so the document has to show
  // three DIFFERENT questions beside them or it proves nothing.
  const dialogClip = async () => page.evaluate(() => {
    const head = [...document.querySelectorAll("h3, h2")].find((x) => /Send an Offer/i.test(x.textContent || ""));
    let box = head?.closest("div");
    for (let i = 0; i < 6 && box?.parentElement; i += 1) {
      const r = box.getBoundingClientRect();
      if (r.width > 380 && r.height > 200) break;
      box = box.parentElement;
    }
    if (!box) return null;
    const r = box.getBoundingClientRect();
    return {
      x: Math.max(0, r.x - 14) + window.scrollX,
      y: Math.max(0, r.y - 14) + window.scrollY,
      width: Math.min(1400, r.width + 28),
      height: Math.min(1400, r.height + 28),
    };
  });
  {
    const c = await dialogClip();
    await shot(page, `${NAME}-typed`, c ? { clip: c } : {});
  }

  await click("Send Offer");
  await pause(8000);

  const clip = await page.evaluate(() => {
    const head = [...document.querySelectorAll("h3, h2")].find((x) => /Send an Offer/i.test(x.textContent || ""));
    let box = head?.closest("div");
    for (let i = 0; i < 6 && box?.parentElement; i += 1) {
      const r = box.getBoundingClientRect();
      if (r.width > 380 && r.height > 200) break;
      box = box.parentElement;
    }
    if (!box) return null;
    const r = box.getBoundingClientRect();
    return {
      x: Math.max(0, r.x - 14) + window.scrollX,
      y: Math.max(0, r.y - 14) + window.scrollY,
      width: Math.min(1400, r.width + 28),
      height: Math.min(1400, r.height + 28),
    };
  });
  await shot(page, NAME, clip ? { clip } : {});
} catch (e) {
  console.error("  FAILED:", e.message);
  process.exitCode = 1;
} finally {
  await browser.close();
}
