// Photograph the 15 September fixes on the LIVE site, signed in as the test
// renter, for the client report. One scenario per argument so a failure costs
// one step:
//
//   node negotiation-journey/sweep_2026-09-15.mjs week luxe deal
//
// Shots land in shots/ as s15-*.png. The `deal` scenario strikes a REAL
// negotiation on a test listing (test data only) and stops on the payment
// page — nothing is paid.
import { open, shot, clickText, pause, dismissBanners, SITE } from "./rig.mjs";

const what = new Set(process.argv.slice(2));
if (!what.size) ["week", "luxe", "deal"].forEach((w) => what.add(w));

const dmy = (d) => `${String(d.getDate()).padStart(2, "0")}-${String(d.getMonth() + 1).padStart(2, "0")}-${d.getFullYear()}`;
const today = new Date();
const plus = (n) => { const d = new Date(today); d.setDate(d.getDate() + n); return d; };

async function offerInput(page) {
  const h = await page.evaluateHandle(() => {
    const label = [...document.querySelectorAll("label, .label")]
      .find((l) => /your offer (per night|for the)/i.test(l.textContent || ""));
    const field = label?.closest(".field") || label?.parentElement;
    return field?.querySelector("input") || null;
  });
  const el = h.asElement();
  if (!el) throw new Error("offer input not found");
  return el;
}

async function dialogClip(page) {
  return page.evaluate(() => {
    const m = document.querySelector(".modal-overlay.on .modal") || document.querySelector(".modal");
    if (!m) return null;
    const r = m.getBoundingClientRect();
    return { x: Math.max(0, r.x - 10) + scrollX, y: Math.max(0, r.y - 10) + scrollY, width: Math.min(780, r.width + 20), height: Math.min(1000, r.height + 20) };
  });
}
const shotDialog = async (page, name) => { const clip = await dialogClip(page); return shot(page, name, clip ? { clip } : {}); };

async function railClip(page) {
  return page.evaluate(() => {
    const t = [...document.querySelectorAll("span,div")].find((n) => (n.innerText || "").trim() === "Total" && n.getBoundingClientRect().width < 200);
    let node = t; for (let i = 0; i < 8 && node?.parentElement; i += 1) { node = node.parentElement; if (node.getBoundingClientRect().width > 300) break; }
    const r = node?.getBoundingClientRect(); if (!r) return null;
    return { x: r.x - 8 + scrollX, y: r.y - 8 + scrollY, width: r.width + 16, height: Math.min(1100, r.height + 16) };
  });
}

async function openListing(page, id, from, to) {
  await page.goto(`${SITE}/property?id=${id}&from=${from}&to=${to}`, { waitUntil: "domcontentloaded" });
  await pause(5000);
  await dismissBanners(page);
}

async function openDialog(page) {
  // The BUTTON under Book Now — not the hidden dialog's own heading, which
  // is also the text "Send an Offer" and is what clickText found first.
  const h = await page.evaluateHandle(() => [...document.querySelectorAll("button")]
    .find((b) => /^Send an Offer/.test((b.innerText || "").trim())) || null);
  const el = h.asElement(); if (!el) throw new Error("Send an Offer button not found");
  await el.scrollIntoView(); await pause(300); await el.click();
  await pause(1800);
}

const { browser, page } = await open("renter", { headless: true });
try {
  if (what.has("week")) {
    // The client's screenshot was 29310 from the 15th; that listing is not
    // free from today any more, and offers are only for stays starting
    // today (the button is not even drawn on an advance stay). So the same
    // seven-night dialog on the QA listing, from today. Photographed, not
    // sent — the `deal` scenario sends.
    const P = Number(process.env.DEAL_PROPERTY || 29302);
    await openListing(page, P, dmy(today), dmy(plus(7)));
    const rc = await railClip(page); await shot(page, "s15-week-card", rc ? { clip: rc } : {});
    await openDialog(page);
    await shotDialog(page, "s15-week-dialog-empty");
    const inp = await offerInput(page);
    await inp.click({ clickCount: 3 }); await inp.type("17000"); await pause(600);
    await shotDialog(page, "s15-week-dialog-typed");
    // And two nights on the same listing: per night, as before.
    await openListing(page, P, dmy(today), dmy(plus(2)));
    await openDialog(page);
    await shotDialog(page, "s15-two-nights-dialog");
  }

  if (what.has("luxe")) {
    // LUXE only dresses a LUXE listing, and 29310 — the client's — takes no
    // offer from today (its next free night is later), so the dialog is
    // opened with no dates chosen, which is enough to show the surface.
    await page.goto(`${SITE}/property?id=29310`, { waitUntil: "domcontentloaded" });
    await pause(5000); await dismissBanners(page);
    const state = await page.evaluate(() => {
      const b = [...document.querySelectorAll("button")].find((x) => /lux/i.test((x.innerText || "") + (x.getAttribute("aria-label") || "")));
      return { label: (b?.innerText || "").trim(), lux: document.documentElement.hasAttribute("data-lux") };
    });
    console.log("  lux state", JSON.stringify(state));
    if (!state.lux) {
      const h = await page.evaluateHandle(() => [...document.querySelectorAll("button")].find((x) => /^lux/i.test((x.innerText || "").trim())) || null);
      const el = h.asElement(); if (el) { await el.click(); await pause(3000); }
    }
    console.log("  lux now", await page.evaluate(() => document.documentElement.hasAttribute("data-lux")));
    await openDialog(page);
    await shotDialog(page, "s15-luxe-dialog");
    const rc = await railClip(page); if (rc) await shot(page, "s15-luxe-card", { clip: rc });
    // Leave the profile in classic.
    await page.keyboard.press("Escape"); await pause(500);
    const exit = await page.evaluateHandle(() => [...document.querySelectorAll("button")].find((x) => /exit lux/i.test((x.innerText || "").trim())) || null);
    const ex = exit.asElement(); if (ex) { await ex.click(); await pause(1500); }
  }

  if (what.has("deal")) {
    // A REAL negotiation on a test listing, starting today, seven nights —
    // the only kind of stay the engine takes offers on. Stops at payment.
    const ID = Number(process.env.DEAL_PROPERTY || 29302);
    await openListing(page, ID, dmy(today), dmy(plus(7)));
    const rc0 = await railClip(page); await shot(page, "s15-deal-card-before", rc0 ? { clip: rc0 } : {});
    await openDialog(page);
    const listedTotal = await page.evaluate(() => {
      const t = [...document.querySelectorAll("p")].map((p) => p.innerText || "").find((x) => /Listed at ₹[\d,]+ for \d+ nights/.test(x));
      const m = t && t.match(/Listed at ₹([\d,]+) for (\d+) nights/);
      return m ? { total: Number(m[1].replace(/,/g, "")), nights: Number(m[2]) } : null;
    });
    console.log("  listed", JSON.stringify(listedTotal));
    if (!listedTotal) throw new Error("the dialog is not asking for a total — is the stay under 7 nights?");
    const offer = Math.round(listedTotal.total * 0.9 / 100) * 100;
    const inp = await offerInput(page);
    await inp.click({ clickCount: 3 }); await inp.type(String(offer)); await pause(500);
    await shotDialog(page, "s15-deal-01-offer");
    await clickText(page, "Send Offer");
    await pause(6000);
    await shotDialog(page, "s15-deal-02-outcome");
    const outcome = await page.evaluate(() => document.querySelector(".modal")?.innerText || "");
    console.log("  outcome:", outcome.replace(/\s+/g, " ").slice(0, 300));
    if (/We can do/.test(outcome)) {
      const acc = await page.evaluateHandle(() => [...document.querySelectorAll("button")].find((b) => /^Accept ₹/.test((b.innerText || "").trim())) || null);
      const el = acc.asElement(); if (!el) throw new Error("no Accept button");
      await el.click(); await pause(6000);
      await shotDialog(page, "s15-deal-03-accepted");
    }
    const after = await page.evaluate(() => document.querySelector(".modal")?.innerText || "");
    console.log("  after:", after.replace(/\s+/g, " ").slice(0, 300));
    if (!/Accepted/.test(after)) throw new Error("the deal was not accepted — see the shots");
    await clickText(page, "Book at this price");
    await pause(6000);
    console.log("  url:", page.url());
    // The rail now carries the deal; photograph it, then go to review.
    if (/property/.test(page.url())) {
      const rc = await railClip(page); if (rc) await shot(page, "s15-deal-04-card-with-deal", { clip: rc });
      await clickText(page, "Book Now"); await pause(6000);
    }
    console.log("  url:", page.url());
    await shot(page, "s15-deal-05-review", { full: true });
    // Tick the policy box and proceed to the payment page (nothing is paid).
    const box = await page.$('input[type="checkbox"]'); if (box) { await box.click(); await pause(400); }
    await clickText(page, "Proceed to Pay"); await pause(7000);
    console.log("  url:", page.url());
    await shot(page, "s15-deal-06-payment", { full: true });
  }
  if (what.has("redo")) {
    // The deal already exists (the `deal` scenario struck it): the listing
    // applies it on its own, and the walk to payment is repeated after a
    // deploy so the photographs show what is live now.
    const ID = Number(process.env.DEAL_PROPERTY || 29302);
    await openListing(page, ID, dmy(today), dmy(plus(7)));
    const rc = await railClip(page); if (rc) await shot(page, "s15-deal-04-card-with-deal", { clip: rc });
    await clickText(page, "Book Now"); await pause(6000);
    console.log("  url:", page.url());
    const sum = await page.evaluate(() => { const h = [...document.querySelectorAll("*")].find((n) => (n.innerText || "").trim() === "Price summary"); const card = h?.closest(".card") || h?.parentElement; const r = card?.getBoundingClientRect(); return r ? { x: r.x - 6 + scrollX, y: r.y - 6 + scrollY, width: r.width + 12, height: r.height + 12 } : null; });
    await shot(page, "s15-deal-05-review-summary", sum ? { clip: sum } : { full: true });
    const box = await page.$('input[type="checkbox"]'); if (box) { await box.click(); await pause(400); }
    await clickText(page, "Proceed to Pay"); await pause(7000);
    console.log("  url:", page.url());
    await shot(page, "s15-deal-06-payment", { full: true });
  }

  if (what.has("pages")) {
    await page.goto(`${SITE}/account/negotiations`, { waitUntil: "domcontentloaded" });
    await pause(6000); await dismissBanners(page);
    // The first thread only — the weekly deal — framed without the sidebar.
    const first = await page.evaluate(() => { const h = [...document.querySelectorAll("h4")].find((x) => /QA Sunrise Villa/.test(x.innerText || "")); const card = h?.closest(".card") || h?.parentElement?.parentElement?.parentElement; const r = card?.getBoundingClientRect(); return r ? { x: r.x - 6 + scrollX, y: r.y - 6 + scrollY, width: r.width + 12, height: Math.min(1000, r.height + 12) } : null; });
    await shot(page, "s15-negotiations-guest", first ? { clip: first } : { full: true });
    // 29310: where you'll sleep, things to know (no "0 km" lines), and the
    // two-night card the client's own report was about.
    await openListing(page, 29310, dmy(plus(2)), dmy(plus(4)));
    const rc = await railClip(page); if (rc) await shot(page, "s15-29310-card-two-nights", { clip: rc });
    const clipOf = async (heading) => page.evaluate((h) => { const n = [...document.querySelectorAll("h2,h3")].find((x) => (x.innerText || "").trim() === h); const sec = n?.parentElement; const r = sec?.getBoundingClientRect(); return r ? { x: r.x - 6 + scrollX, y: r.y - 6 + scrollY, width: r.width + 12, height: Math.min(900, r.height + 12) } : null; }, heading);
    const sleep = await clipOf("Where you'll sleep"); if (sleep) await shot(page, "s15-29310-sleep", { clip: sleep });
    const know = await clipOf("Things to know"); if (know) await shot(page, "s15-29310-things-to-know", { clip: know });
  }
} catch (e) {
  console.error("FAILED:", e.message);
  await shot(page, "s15-failure");
  process.exitCode = 1;
} finally {
  await browser.close();
}
