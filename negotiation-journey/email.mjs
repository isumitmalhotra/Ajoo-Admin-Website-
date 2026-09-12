// Photograph ONE notification email, from the real inbox it was delivered to.
//
// The notification layer reaches a person three ways at once — a popup on
// whatever screen they are on, the bell, and an email — and the third is the
// one a document cannot demonstrate from inside the product.
//
// ── Why one message and not the inbox ──────────────────────────────────────
//
// A screenshot of an inbox list photographs every subject line in it, and this
// address also receives sign-in codes. One-time codes must never appear in a
// document, a log or a screen recording, so this opens the single message it
// wants by subject and never renders the list.
//
//   node negotiation-journey/email.mjs "last price"
import { open, shot, pause } from "./rig.mjs";

/** The test renter's public mailbox. A mailinator address, never a real one. */
const INBOX = "https://www.mailinator.com/v4/public/inboxes.jsp?to=aajoo.renter1";
const WANT = process.argv[2] || "last price";
const NAME = process.argv[3] || "n13-email";

const { browser, page } = await open("renter");
try {
  await page.goto(INBOX, { waitUntil: "domcontentloaded" });
  await pause(9000);

  // A synthetic .click() on the row does nothing: the list is an Angular view
  // whose handler is bound to a real pointer event. Measure the row, then
  // click it with the mouse.
  const box = await page.evaluate((want) => {
    const rows = [...document.querySelectorAll("tr")];
    const hit = rows.find((r) => (r.innerText || "").toLowerCase().includes(want.toLowerCase()));
    if (!hit) return null;
    hit.scrollIntoView({ block: "center" });
    const r = hit.getBoundingClientRect();
    return { x: r.x + r.width / 2, y: r.y + r.height / 2, text: (hit.innerText || "").slice(0, 120) };
  }, WANT);
  const opened = box?.text || null;
  if (box) {
    await page.mouse.click(box.x, box.y);
  }

  if (!opened) {
    console.log(`  no message matching "${WANT}" — nothing photographed`);
    process.exitCode = 1;
  } else {
    console.log(`  opened: ${opened.replace(/\s+/g, " ")}`);
    // The message pane is sized to the window, and the email runs past it --
    // the first capture stopped halfway through the button. Give it room.
    await page.setViewport({ width: 1440, height: 1500 });
    await pause(9000);
    // The pane renders empty first and fills in, so a clip measured too early
    // is zero-width -- which Puppeteer refuses outright rather than saving a
    // blank. Wait for the frame to have a size before measuring.
    await page.waitForFunction(() => {
      const f = document.querySelector("#html_msg_body") || document.querySelector("iframe");
      return !!f && f.getBoundingClientRect().width > 200;
    }, { timeout: 20000 }).catch(() => null);
    // The body renders in an iframe; clip to it so the surrounding mailinator
    // chrome — and the inbox list behind it — stay out of the picture.
    const clip = await page.evaluate(() => {
      const f = document.querySelector("#html_msg_body") || document.querySelector("iframe");
      if (!f) return null;
      f.scrollIntoView({ block: "start" });
      const r = f.getBoundingClientRect();
      return {
        x: Math.max(0, r.x) + window.scrollX,
        y: Math.max(0, r.y) + window.scrollY,
        width: Math.min(1400, r.width),
        height: Math.min(1000, r.height),
      };
    });
    await pause(1200);
    await shot(page, NAME, clip && clip.width > 10 && clip.height > 10 ? { clip } : {});
  }
} catch (e) {
  console.error("  FAILED:", e.message);
  process.exitCode = 1;
} finally {
  await browser.close();
}
