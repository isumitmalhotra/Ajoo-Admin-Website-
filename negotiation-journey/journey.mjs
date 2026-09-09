// Drive every negotiation scenario on the LIVE site and photograph both sides.
//
// One scenario per invocation, so the database can be reset between them and a
// failure costs one step rather than the whole run:
//
//   node negotiation-journey/journey.mjs s2-counter
//
// Every step saves a PNG under shots/ whether or not it worked, because the
// only way to diagnose a headful run afterwards is to look at what it saw.
import { open, shot, clickText, pause, dismissBanners, SITE } from "./rig.mjs";

const PROPERTY = 29291;
const LISTING = `${SITE}/property?id=${PROPERTY}`;

// ── page helpers ────────────────────────────────────────────────────────────

/** Type into the offer dialog's price box. */
async function setOffer(page, amount) {
  const box = await page.evaluateHandle(() => {
    const label = [...document.querySelectorAll("label, .label")]
      .find((l) => /your offer per night/i.test(l.textContent || ""));
    if (label) {
      const field = label.closest(".field") || label.parentElement;
      return field?.querySelector("input") || null;
    }
    return document.querySelector('input[inputmode="numeric"]');
  });
  const el = box.asElement();
  if (!el) throw new Error("offer price input not found");
  await el.click({ clickCount: 3 });
  await page.keyboard.press("Backspace");
  await el.type(String(amount));
}

/**
 * Open the date picker inside the MODAL and take the first two enabled days.
 *
 * There are two CHECK-IN controls on this page — one in the booking rail and
 * one in the offer dialog — and clicking the rail's does nothing to the
 * dialog. The offer then posts with no dates and the server refuses it, which
 * is exactly what the first run photographed.
 */
async function openDatePicker(page) {
  const opened = await page.evaluate(() => {
    const label = [...document.querySelectorAll('div')].find((n) =>
      n.childNodes.length === 1 &&
      n.firstChild?.nodeType === 3 &&
      /^CHECK-IN$/i.test(n.textContent.trim()) &&
      n.closest('.modal'));
    const box = label?.parentElement;
    if (!box) return false;
    box.click();
    return true;
  });
  if (!opened) throw new Error('check-in control not found inside the dialog');
  await pause(1400);
}

/** Click the nth (0-based) selectable day cell in the open calendar. */
async function clickDay(page, index) {
  const label = await page.evaluate((i) => {
    // The calendar is rendered OUTSIDE the modal element, so scoping to
    // '.modal button' finds nothing. Scope by what is on screen instead: only
    // the open picker's cells are visible, and disabled days (the past, and
    // days the host does not sell) are skipped.
    const days = [...document.querySelectorAll('button')].filter((b) => {
      if (!/^[0-9]{1,2}$/.test((b.innerText || '').trim()) || b.disabled) return false;
      if (b.getAttribute('aria-disabled') === 'true') return false;
      const r = b.getBoundingClientRect();
      // NOT offsetParent: the picker sits in a fixed-position layer, and
      // offsetParent is null for everything inside one — which excluded every
      // day in the calendar.
      return r.width > 0 && r.height > 0 && r.bottom > 0 && r.top < innerHeight;
    });
    const cell = days[i];
    if (!cell) return null;
    cell.click();
    return cell.innerText.trim();
  }, index);
  if (!label) throw new Error(`no selectable day at index ${index}`);
  await pause(1100);
  return label;
}

/** Today and tomorrow: the stay a negotiation is for. */
async function pickTodayAndTomorrow(page) {
  await openDatePicker(page);
  const from = await clickDay(page, 0);
  const to = await clickDay(page, 1);
  console.log(`  dates  ${from} -> ${to}`);
  return [from, to];
}
/** Open the listing and the Send an Offer dialog. */
async function openOfferDialog(page) {
  await page.goto(LISTING, { waitUntil: "domcontentloaded" });
  await pause(3500);
  await dismissBanners(page);
  await clickText(page, "Send an Offer");
  await pause(1800);
}

/** The dialog is tall; frame just the dialog for a clean shot. */
async function dialogClip(page) {
  return page.evaluate(() => {
    const heads = [...document.querySelectorAll("h2,h3,h4,div")]
      .filter((n) => (n.innerText || "").trim() === "Send an Offer");
    const dialog = heads[0]?.closest("div[class], div");
    let node = dialog;
    for (let i = 0; i < 4 && node?.parentElement; i += 1) {
      const r = node.parentElement.getBoundingClientRect();
      if (r.width > 380 && r.width < 760) node = node.parentElement;
      else break;
    }
    const r = node?.getBoundingClientRect();
    if (!r || r.width < 200) return null;
    return {
      x: Math.max(0, r.x - 12) + window.scrollX,
      y: Math.max(0, r.y - 12) + window.scrollY,
      width: Math.min(760, r.width + 24), height: Math.min(900, r.height + 24),
    };
  });
}

async function shotDialog(page, name) {
  const clip = await dialogClip(page);
  return shot(page, name, clip ? { clip } : {});
}

// ── scenarios ───────────────────────────────────────────────────────────────

const scenarios = {
  /** The listing as a guest finds it, before anything is offered. */
  async "s0-listing"(page) {
    await page.goto(LISTING, { waitUntil: "domcontentloaded" });
    await pause(3500);
    await dismissBanners(page);
    await page.evaluate(() => window.scrollBy(0, 320));
    await pause(800);
    // Framed on the booking rail rather than the whole page. The rail is what
    // this document is about — "Send an Offer" sitting under "Book Now" — and
    // the demo listing has no photographs, so a full-width shot would lead
    // with an empty gallery that has nothing to do with negotiation.
    // Anchored on the button itself and expanded upward to take in the price
    // and the date fields. Walking up the DOM for a "card" found the wrong
    // ancestor and cropped the button off the bottom.
    const clip = await page.evaluate(() => {
      const btn = [...document.querySelectorAll("button")]
        .find((b) => /Send an Offer/.test(b.innerText || ""));
      const r = btn?.getBoundingClientRect();
      if (!r) return null;
      const top = Math.max(0, r.bottom - 360);
      return {
        x: Math.max(0, r.x - 26) + window.scrollX,
        y: top + window.scrollY,
        width: r.width + 52,
        height: Math.min(430, r.bottom + 46 - top),
      };
    });
    await shot(page, "s0-listing-rail", clip ? { clip } : {});
  },

  /** An offer at or above the ideal: taken on the spot. */
  async "s1-accept"(page) {
    await openOfferDialog(page);
    await setOffer(page, 1750);
    await pickTodayAndTomorrow(page);
    await shotDialog(page, "s1a-offer-1750");
    await clickText(page, "Send Offer");
    await pause(7000);
    await shotDialog(page, "s1b-accepted");
    await page.evaluate(() => window.scrollTo(0, 260));
    await pause(600);
    await shot(page, "s1c-rail-deal");
  },

  /** Below the ideal: answered at once, without the host. */
  async "s2-counter"(page) {
    await openOfferDialog(page);
    await setOffer(page, 1100);
    await pickTodayAndTomorrow(page);
    await shotDialog(page, "s2a-offer-1100");
    await clickText(page, "Send Offer");
    await pause(7000);
    await shotDialog(page, "s2b-counter");
  },

  /**
   * One offer, one counter, photographed — for the three shots either side of
   * the host's minimum that show the floor cannot be located.
   *
   * Called as: node negotiation-journey/journey.mjs probe 1490
   */
  async "probe"(page) {
    const amount = Number(process.argv[3]);
    if (!amount) throw new Error("probe needs an amount: journey.mjs probe 1490");
    await openOfferDialog(page);
    await setOffer(page, amount);
    await pickTodayAndTomorrow(page);
    await clickText(page, "Send Offer");
    await pause(7000);
    await shotDialog(page, `s3-offer-${amount}`);
  },

  /** Below the MINIMUM: the identical answer. That is the point. */
  async "s3-below-floor"(page) {
    await openOfferDialog(page);
    await setOffer(page, 100);
    await pickTodayAndTomorrow(page);
    await clickText(page, "Send Offer");
    await pause(7000);
    await shotDialog(page, "s3-below-floor-counter");
  },

  /** Taking the counter: deal struck, coupon issued. */
  async "s4-take-counter"(page) {
    await openOfferDialog(page);
    await setOffer(page, 1100);
    await pickTodayAndTomorrow(page);
    await clickText(page, "Send Offer");
    await pause(7000);
    await page.evaluate(() => {
      const b = [...document.querySelectorAll("button")].find((x) => /^Accept /.test((x.innerText || "").trim()));
      b?.click();
    });
    await pause(7000);
    await shotDialog(page, "s4a-deal-struck");
    await page.evaluate(() => window.scrollTo(0, 260));
    await pause(800);
    await shot(page, "s4b-rail-deal");
  },

  /** Countering the counter, below the line: it reaches the host. */
  async "s5-counter-back"(page) {
    await openOfferDialog(page);
    await setOffer(page, 1100);
    await pickTodayAndTomorrow(page);
    await clickText(page, "Send Offer");
    await pause(7000);
    await clickText(page, "Counter this price");
    await pause(1200);
    await page.evaluate(() => {
      const i = document.querySelector("#counter-price");
      if (i) { i.focus(); }
    });
    await page.type("#counter-price", "1600");
    await shotDialog(page, "s5a-counter-back-1600");
    await clickText(page, "Send to the host");
    await pause(7000);
    await shotDialog(page, "s5b-with-the-host");
  },

  /** Countering the counter ABOVE the line: taken, no host needed. */
  async "s6-counter-back-clears"(page) {
    await openOfferDialog(page);
    await setOffer(page, 100);
    await pickTodayAndTomorrow(page);
    await clickText(page, "Send Offer");
    await pause(7000);
    await clickText(page, "Counter this price");
    await pause(1200);
    await page.type("#counter-price", "1750");
    await clickText(page, "Send to the host");
    await pause(8000);
    await shotDialog(page, "s6-counter-back-accepted");
  },

  /** Above the list price: there is nothing to negotiate upward. */
  async "s7-above-list"(page) {
    await openOfferDialog(page);
    await setOffer(page, 2500);
    await pickTodayAndTomorrow(page);
    await clickText(page, "Send Offer");
    await pause(3000);
    await shotDialog(page, "s7-above-list");
  },

  /** A stay starting tomorrow is an advance booking, and is not negotiable. */
  async "s8-advance"(page) {
    await openOfferDialog(page);
    await setOffer(page, 1500);
    // Skip today: the second and third selectable days are tomorrow and the
    // day after, which makes this an advance booking. Uses the same helper as
    // every other scenario — its own copy of the day selector is what left
    // this one photographing an empty date field.
    await openDatePicker(page);
    const from = await clickDay(page, 1);
    const to = await clickDay(page, 2);
    console.log(`  dates  ${from} -> ${to} (advance booking)`);
    await clickText(page, "Send Offer");
    await pause(4000);
    await shotDialog(page, "s8a-advance-refused");
    await page.evaluate(() => window.scrollTo(0, 260));
    await pause(600);
    await shot(page, "s8b-advance-rail");
  },

  /** The guest's own record of the conversation. */
  async "s9-guest-negotiations"(page) {
    await page.goto(`${SITE}/account/negotiations`, { waitUntil: "domcontentloaded" });
    await pause(3500);
    await dismissBanners(page);
    // Just the current conversation. The page also lists older test threads
    // from previous sessions, one of which still carries wording the product
    // has since retired — showing that to a client would raise a question the
    // document cannot answer.
    const clip = await page.evaluate(() => {
      const head = [...document.querySelectorAll("*")].find(
        (n) => n.childElementCount === 0 && (n.textContent || "").trim() === "Aajoo Homes");
      // Walk up until the box is card-sized in BOTH directions. Stopping at
      // width alone caught the title row, which is 700 wide and 30 tall.
      let card = head;
      for (let i = 0; i < 10 && card?.parentElement; i += 1) {
        card = card.parentElement;
        const r = card.getBoundingClientRect();
        if (r.width > 700 && r.height > 200) break;
      }
      const r = card?.getBoundingClientRect();
      if (!r) return null;
      return {
        x: Math.max(0, r.x - 14) + window.scrollX,
        y: Math.max(0, r.y - 14) + window.scrollY,
        width: r.width + 28,
        height: r.height + 28,
      };
    });
    await shot(page, "s9-guest-negotiations", clip ? { clip } : { full: true });
  },

  // ── host side ─────────────────────────────────────────────────────────────

  async "h1-host-negotiations"(page) {
    await page.goto(`${SITE}/host/negotiations`, { waitUntil: "domcontentloaded" });
    await pause(4000);
    await dismissBanners(page);
    await shot(page, "h1-host-negotiations", { full: true });
  },

  async "h2-host-notifications"(page) {
    await page.goto(`${SITE}/host/notifications`, { waitUntil: "domcontentloaded" });
    await pause(4000);
    await dismissBanners(page);
    // Framed on the counter-back notice, which is what this section is about:
    // the one moment the host is actually asked something.
    //
    // Not the whole feed. It runs to eight pages, and older rows keep whatever
    // wording the product had when they were written — including an
    // acceptance notice corrected on 2026-09-09 that names the wrong price
    // tier. Those rows cannot be rewritten after the fact, and showing a
    // client copy we have already fixed would raise a question this document
    // cannot answer.
    const clip = await page.evaluate(() => {
      const row = [...document.querySelectorAll("*")].find(
        (n) => n.childElementCount === 0 && (n.textContent || "").trim() === "The guest countered back");
      if (!row) return null;
      let card = row;
      for (let i = 0; i < 6 && card?.parentElement; i += 1) {
        card = card.parentElement;
        const r = card.getBoundingClientRect();
        if (r.width > 600 && r.height > 60) break;
      }
      const r = card.getBoundingClientRect();
      return {
        x: Math.max(0, r.x - 12) + window.scrollX,
        y: Math.max(0, r.y - 12) + window.scrollY,
        width: Math.min(820, r.width + 24),
        height: Math.min(200, r.height + 24),
      };
    });
    await shot(page, "h2-host-notifications", clip ? { clip } : {});
  },

  async "h3-host-dashboard"(page) {
    await page.goto(`${SITE}/host`, { waitUntil: "domcontentloaded" });
    await pause(4000);
    await dismissBanners(page);
    await shot(page, "h3-host-dashboard");
  },
};

// ── run one ─────────────────────────────────────────────────────────────────
const name = process.argv[2];
const role = name?.startsWith("h") ? "host" : "renter";
const fn = scenarios[name];
if (!fn) {
  console.log("scenarios:\n  " + Object.keys(scenarios).join("\n  "));
  process.exit(1);
}

const { browser, page } = await open(role);
try {
  console.log(`\n=== ${name}  (${role}) ===`);
  await fn(page);
  console.log("  done");
} catch (e) {
  console.error("  FAILED:", e.message);
  await shot(page, `FAILED-${name}`).catch(() => {});
  process.exitCode = 1;
} finally {
  await browser.close();
}
