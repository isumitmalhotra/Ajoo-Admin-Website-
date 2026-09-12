// The renter's half of the cross-device run.
//
// The Android suite needs a real offer sitting on a real host's phone. The
// emulator is signed in as the test host who owns 29303, and the renter is the
// Chrome profile this repo already drives — so the guest side runs here and the
// host side is driven on the device.
//
//   node negotiation-journey/android.mjs 29303 900 850
//
// Arguments: property, the opening offer, and the price to counter back with
// once the platform has answered. Pass no counter-back to stop after round one.
import { open, shot, pause, dismissBanners, SITE } from "./rig.mjs";

const PROPERTY = process.argv[2] || "29303";
const OPENING = process.argv[3] || "900";
const COUNTER = process.argv[4] || null;
const FROM = process.argv[5] || "12-09-2026";
const TO = process.argv[6] || "13-09-2026";
const TAG = `and-${PROPERTY}`;

const { browser, page } = await open("renter");

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

const dialogShot = async (name) => {
  await pause(1200);
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
  await shot(page, name, clip ? { clip } : {});
};

try {
  await page.goto(`${SITE}/property?id=${PROPERTY}&from=${FROM}&to=${TO}&guests=2`, { waitUntil: "domcontentloaded" });
  await pause(7000);
  await dismissBanners(page);

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
  await el.type(String(OPENING));
  await pause(400);
  await dialogShot(`${TAG}-1-typed`);

  await click("Send Offer");
  await pause(8000);
  await dialogShot(`${TAG}-2-answer`);

  if (COUNTER) {
    await click("Counter this price");
    await pause(1400);
    const h2 = await page.evaluateHandle(() => {
      const dlg = [...document.querySelectorAll("div")].find((d) => /Your counter, per night/i.test(d.textContent || "") && d.querySelector("input"));
      return dlg?.querySelector("input") || null;
    });
    const el2 = h2.asElement();
    if (!el2) throw new Error("counter input not found");
    await el2.click({ clickCount: 3 });
    await page.keyboard.press("Backspace");
    await el2.type(String(COUNTER));
    await pause(400);
    await click("Send to the host");
    await pause(9000);
    await dialogShot(`${TAG}-3-escalated`);
  }
} catch (e) {
  console.error("  FAILED:", e.message);
  await shot(page, `FAILED-${TAG}`).catch(() => {});
  process.exitCode = 1;
} finally {
  await browser.close();
}
