// Drive the UPDATED negotiation engine on the LIVE site and photograph both
// sides — the September 12th rebuild.
//
// The original journey.mjs photographed the engine as it stood on 9 September.
// Everything below changed after that and needed re-shooting, or is new:
//
//   the round cap is gone            a thread runs until somebody settles it
//   an auto-accept answers in-thread it used to write the guest's row and
//                                    nothing else, so accepted offers read as
//                                    a column of unanswered messages
//   a decline leaves a price         the host's last counter, one hour, locked
//                                    to those nights
//   a held deal bars its own nights  accepted or parting, the button greys
//   notifications announce themselves a popup on any screen, and an email
//   the ceiling is the DATED price   not the flat nightly column
//
// One scenario per invocation, so the database can be reset between them and a
// failure costs one step rather than the whole run:
//
//   node negotiation-journey/journey2.mjs n2-counter
//   node negotiation-journey/journey2.mjs            # lists them all
//
// ── Why the dates come from the URL ─────────────────────────────────────────
//
// The old driver clicked its way through the calendar, which is the most
// brittle thing a script can do to this page: there are two CHECK-IN controls
// (the rail's and the dialog's), the grid greys days out for rules that vary
// by listing, and a mis-click produces an offer with no dates that the server
// refuses. The property page reads ?from=&to=&guests= — the same links My
// Negotiations and search already use — so the stay is set before anything is
// clicked, and the dialog inherits it.
import { open, shot, pause, dismissBanners, SITE } from "./rig.mjs";

/** Sam's listing — the same one the first document used, so the two compare. */
const PROPERTY = 29291;
/** Tonight. Negotiation is a same-day mechanism, so check-in is always today. */
const FROM = "12-09-2026";
const TO = "13-09-2026";
const STAY = `${SITE}/property?id=${PROPERTY}&from=${FROM}&to=${TO}&guests=2`;

/* ── page helpers ─────────────────────────────────────────────────────────── */

async function openListing(page, url = STAY) {
  await page.goto(url, { waitUntil: "domcontentloaded" });
  await pause(6500);
  await dismissBanners(page);
  await pause(600);
}

/** A full-page shot taken from a scrolled page puts the sticky header mid-image. */
async function shotFull(page, name) {
  await page.evaluate(() => window.scrollTo(0, 0));
  await pause(700);
  await shot(page, name, { full: true });
}

/** Scroll the booking rail into view and return its bounding box for a clip. */
async function railBox(page) {
  return page.evaluate(() => {
    const rail = document.querySelector(".rail-card") || document.querySelector(".prop-rail");
    if (!rail) return null;

    // The deal banner is a SIBLING above the card, not part of it, so a clip
    // on the card alone sliced the discount, the code and the countdown in
    // half -- the three facts the banner exists to carry.
    const banner = [...document.querySelectorAll("div")].find((d) => {
      const t = d.textContent || "";
      if (!/negotiated deal is on|last price is yours|only applies to these dates/i.test(t)) return false;
      const b = d.getBoundingClientRect();
      return b.width > 200 && b.width < 560 && b.height > 40 && b.height < 400;
    });

    const union = () => {
      const r = rail.getBoundingClientRect();
      if (!banner) return { x: r.x, y: r.y, right: r.right, bottom: r.bottom };
      const b = banner.getBoundingClientRect();
      return {
        x: Math.min(r.x, b.x),
        y: Math.min(r.y, b.y),
        right: Math.max(r.right, b.right),
        bottom: r.bottom,
      };
    };

    // Put the TOP of what is being photographed 20px below the top of the
    // window, and measure again. scrollIntoView({block:"center"}) centred the
    // card and left the banner above the fold, where a negative y clamps to
    // zero and the crop starts mid-sentence -- which is how the first pass
    // photographed "Your negotiated deal is on" with the figure sliced off.
    const before = union();
    window.scrollBy(0, before.y - 20);
    const u = union();
    return {
      x: Math.max(0, u.x - 14) + window.scrollX,
      y: Math.max(0, u.y - 14) + window.scrollY,
      width: Math.min(1400, u.right - u.x + 28),
      height: Math.min(1400, u.bottom - u.y + 28),
    };
  });
}

async function shotRail(page, name) {
  // A rail carrying a deal is taller than the window: banner, price, dates,
  // the breakdown, two buttons and the sentence explaining the second one.
  // Puppeteer renders a clip that runs past the bottom of the viewport as
  // white, which is how the parting-price explanation came out sliced in half
  // with an inch of nothing under it. Give the page room, then give it back.
  const was = page.viewport();
  await page.setViewport({ ...was, height: 1400 });
  await pause(1200);
  const clip = await railBox(page);
  await shot(page, name, clip ? { clip } : {});
  await page.setViewport(was);
}

/**
 * Just the offer control and the sentence under it.
 *
 * A full rail clip of a barred negotiation is the same photograph as the rail
 * carrying the deal -- the difference is one button and two lines, and in a
 * document the reader needs those pointed at rather than hunted for.
 */
async function shotOfferBlock(page, name) {
  await pause(900);
  const clip = await page.evaluate(() => {
    const btn = [...document.querySelectorAll("button")]
      .find((b) => /send an offer/i.test((b.innerText || "").trim()));
    if (!btn) return null;
    btn.scrollIntoView({ block: "center" });
    const b = btn.getBoundingClientRect();
    // Down to the end of the explanation, which is the half that says WHY.
    let bottom = b.bottom;
    let n = btn.nextElementSibling;
    for (let i = 0; i < 3 && n; i += 1) {
      const r = n.getBoundingClientRect();
      if (r.height > 0 && r.height < 200) bottom = Math.max(bottom, r.bottom);
      n = n.nextElementSibling;
    }
    return {
      x: Math.max(0, b.x - 16) + window.scrollX,
      y: Math.max(0, b.y - 16) + window.scrollY,
      width: Math.min(1400, b.width + 32),
      height: Math.min(1400, bottom - b.y + 32),
    };
  });
  await shot(page, name, clip ? { clip } : {});
}

/** Click the button whose own text starts with the given words. */
async function clickButton(page, text) {
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
  return true;
}

/**
 * Click the button whose text is EXACTLY the given words.
 *
 * "Decline" is also the first word of the "Declined (0)" filter tab, which sits
 * above the card in DOM order — so a startsWith match silently switched tabs
 * and photographed an empty list instead of declining anything.
 */
async function clickExactButton(page, text) {
  const h = await page.evaluateHandle((t) => {
    const want = t.toLowerCase();
    return [...document.querySelectorAll("button")]
      .find((b) => !b.disabled && (b.innerText || "").trim().toLowerCase() === want) || null;
  }, text);
  const el = h.asElement();
  if (!el) throw new Error(`no enabled button reading exactly "${text}"`);
  await el.scrollIntoView();
  await pause(350);
  await el.click();
  return true;
}

/** Open the offer dialog from the rail. */
async function openOfferDialog(page) {
  await clickButton(page, "Send an Offer");
  await pause(1600);
}

/** Type an amount into the dialog's price box. */
async function setOffer(page, amount) {
  const h = await page.evaluateHandle(() => {
    const dlg = [...document.querySelectorAll("div")].find((d) => /Your offer per night/i.test(d.textContent || "") && d.querySelector("input"));
    return dlg?.querySelector("input") || document.querySelector('input[inputmode="numeric"]');
  });
  const el = h.asElement();
  if (!el) throw new Error("offer price input not found");
  await el.click({ clickCount: 3 });
  await page.keyboard.press("Backspace");
  await el.type(String(amount));
  await pause(400);
}

/** The dialog panel, clipped, so the shot is the thing and not the page. */
async function shotDialog(page, name) {
  await pause(1200);
  const clip = await page.evaluate(() => {
    const head = [...document.querySelectorAll("h3, h2")].find((h) => /Send an Offer/i.test(h.textContent || ""));
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
}

/** Send an offer and photograph whatever comes back. */
async function offer(page, amount, name) {
  await openOfferDialog(page);
  await setOffer(page, amount);
  await shotDialog(page, `${name}-typed`);
  await clickButton(page, "Send Offer");
  await pause(7000);
  await shotDialog(page, name);
}

/* ── the scenarios ────────────────────────────────────────────────────────── */

const scenarios = {
  /** The listing as a guest finds it, before anything has been offered. */
  async "n1-rail"(page) {
    await openListing(page);
    await shotRail(page, "n1-rail");
  },

  /**
   * Below the accept line — answered by the platform, in the host's name, on
   * the spot. The panel now carries a way back to the thread; it used to end
   * in a dialog the guest could dismiss and never find again.
   */
  async "n2-counter"(page) {
    await openListing(page);
    await offer(page, 1800, "n2-counter");
  },

  /** At or above the line — taken immediately, at the price the guest named. */
  async "n3-accepted"(page) {
    await openListing(page);
    await offer(page, 2400, "n3-accepted");
    await openListing(page);
    await shotRail(page, "n3-rail-deal");
  },

  /** The thread: every offer has an answer under it. */
  async "n4-thread"(page) {
    await page.goto(`${SITE}/account/negotiations`, { waitUntil: "domcontentloaded" });
    await pause(7000);
    await dismissBanners(page);
    await shotFull(page, "n4-thread");
  },

  /** A price already agreed for these nights bars another negotiation. */
  async "n5-already-agreed"(page) {
    await openListing(page);
    await shotOfferBlock(page, "n5-already-agreed");
  },

  /** Argued back, under the floor — this is the one that reaches a person. */
  async "n6-escalated"(page) {
    await openListing(page);
    await offer(page, 1800, "n6-counter");
    await clickButton(page, "Counter this price");
    await pause(1200);
    const h = await page.evaluateHandle(() => {
      const dlg = [...document.querySelectorAll("div")].find((d) => /Your counter, per night/i.test(d.textContent || "") && d.querySelector("input"));
      return dlg?.querySelector("input") || null;
    });
    const el = h.asElement();
    if (!el) throw new Error("counter input not found");
    await el.click({ clickCount: 3 });
    await page.keyboard.press("Backspace");
    await el.type("1600");
    await shotDialog(page, "n6-counter-typed");
    await clickButton(page, "Send to the host");
    await pause(8000);
    await shotDialog(page, "n6-escalated");
  },

  /** Above what the stay actually costs tonight — refused, with that figure. */
  async "n7-above-list"(page) {
    await openListing(page);
    await openOfferDialog(page);
    await setOffer(page, 2600);
    await clickButton(page, "Send Offer");
    await pause(3000);
    await shotDialog(page, "n7-above-list");
  },

  /** A stay starting tomorrow is an advance booking, not a negotiation. */
  async "n8-advance"(page) {
    // 20-23 September is booked on this listing, and the rail clears dates it
    // cannot sell — which photographs as "no longer available", not as the
    // advance-booking rule this scenario is about.
    await openListing(page, `${SITE}/property?id=${PROPERTY}&from=25-09-2026&to=27-09-2026&guests=2`);
    await shotRail(page, "n8-advance");
  },

  /** After the host declines: the price they left, and the shut door. */
  async "n9-parting"(page) {
    await openListing(page);
    await shotRail(page, "n9-parting");
  },

  /** The guest's own record of a negotiation the host ended. */
  async "n10-thread-declined"(page) {
    await page.goto(`${SITE}/account/negotiations`, { waitUntil: "domcontentloaded" });
    await pause(7000);
    await dismissBanners(page);
    await shotFull(page, "n10-thread-declined");
  },

  /** The calendar explaining a rule that only appears once you act. */
  async "n11-calendar"(page) {
    await openListing(page, `${SITE}/property?id=29302`);
    await page.evaluate(() => {
      const label = [...document.querySelectorAll("div")].find((n) =>
        n.childNodes.length === 1 && n.firstChild?.nodeType === 3 && /^CHECK-IN$/i.test(n.textContent.trim()));
      (label?.parentElement || label)?.click();
    });
    await pause(1600);
    // Pick the first selectable day, which sets a check-in and makes the
    // minimum-stay rule apply to everything before the earliest checkout.
    await page.evaluate(() => {
      const days = [...document.querySelectorAll("button")].filter((b) => /^\d{1,2}$/.test((b.textContent || "").trim()) && !b.disabled);
      days[0]?.click();
    });
    await pause(1600);
    const clip = await page.evaluate(() => {
      const panel = [...document.querySelectorAll("div")].find((d) => /Clear dates/.test(d.textContent || "") && getComputedStyle(d).overflowY === "auto");
      if (!panel) return null;
      const r = panel.getBoundingClientRect();
      return {
        x: Math.max(0, r.x - 10) + window.scrollX,
        y: Math.max(0, r.y - 10) + window.scrollY,
        width: Math.min(1400, r.width + 20),
        height: Math.min(1400, r.height + 20),
      };
    });
    await shot(page, "n11-calendar", clip ? { clip } : {});
  },

  /**
   * The bell, for the same events.
   *
   * The popup is the announcement; this is the record. They resolve the same
   * notification through the same function, so a popup that opens Negotiations
   * cannot sit beside a bell entry that opens Bookings.
   */
  async "n12-bell"(page) {
    await page.goto(`${SITE}/account/notifications`, { waitUntil: "domcontentloaded" });
    await pause(7000);
    await dismissBanners(page);
    await shotFull(page, "n12-bell");
  },

  /**
   * Which of these reach you by email.
   *
   * The client's rule, 12 September: an email for everything EXCEPT payment
   * receipts and ordinary chat messages -- a receipt already arrives as an
   * invoice, and a chat that emails every line is a chat nobody reads. The
   * screen is what a guest can change about that.
   */
  async "n14-prefs"(page) {
    await page.goto(`${SITE}/account/settings`, { waitUntil: "domcontentloaded" });
    await pause(8000);
    await dismissBanners(page);
    const clip = await page.evaluate(() => {
      const head = [...document.querySelectorAll("h2, h3, h4")]
        .find((h) => /notification/i.test(h.textContent || ""));
      const box = head?.closest("div");
      if (!box) return null;
      box.scrollIntoView({ block: "start" });
      window.scrollBy(0, -20);
      const r = box.getBoundingClientRect();
      return {
        x: Math.max(0, r.x - 14) + window.scrollX,
        y: Math.max(0, r.y - 14) + window.scrollY,
        width: Math.min(1400, r.width + 28),
        height: Math.min(1300, r.height + 28),
      };
    });
    await pause(900);
    await shot(page, "n14-prefs", clip && clip.width > 10 ? { clip } : {});
  },

  /* ── the host's side ─────────────────────────────────────────────────── */

  /** The offer waiting on Sam, with the below-floor warning only he sees. */
  async "h1-host-offer"(page) {
    await page.goto(`${SITE}/host/negotiations`, { waitUntil: "domcontentloaded" });
    await pause(7000);
    await dismissBanners(page);
    await shotFull(page, "h1-host-offer");
  },

  /** Declining — and what the host is told it will leave behind. */
  async "h2-host-decline"(page) {
    await page.goto(`${SITE}/host/negotiations`, { waitUntil: "domcontentloaded" });
    await pause(7000);
    await dismissBanners(page);
    await shot(page, "h2-host-decline-before");
    await clickExactButton(page, "Decline");
    await pause(5000);
    await shot(page, "h2-host-decline", { full: true });
  },

  /** The same events in the host's feed. An offer nobody sees is an offer that expires. */
  async "h5-host-bell"(page) {
    await page.goto(`${SITE}/host/notifications`, { waitUntil: "domcontentloaded" });
    await pause(7000);
    await dismissBanners(page);
    await shotFull(page, "h5-host-bell");
  },

  /** The host's own thread, with the platform's words marked as such. */
  async "h3-host-thread"(page) {
    await page.goto(`${SITE}/host/negotiations`, { waitUntil: "domcontentloaded" });
    await pause(7000);
    await dismissBanners(page);
    await shotFull(page, "h3-host-thread");
  },
};

/* --- both sides at once ---------------------------------------------------- */
//
// Some of what shipped on 12 September only exists BETWEEN the two browsers:
// the host declines in one window and a popup appears in the other, on
// whatever page the guest happens to be reading. One browser cannot photograph
// that, so these scenarios open two.

/**
 * The live popup, waited for and then photographed in place.
 *
 * Three things went wrong before this worked.
 *
 * It looked for an element that was itself `position: fixed`, and
 * react-hot-toast fixes the CONTAINER while the card inside it is positioned
 * normally -- so nothing matched.
 *
 * Loosening that to "any box in the lower half whose text mentions an offer"
 * then matched the listing's own "Price negotiable -- send the host an offer"
 * card, and the document nearly carried a photograph of the Safety & property
 * panel labelled as a live notification.
 *
 * And the window without focus is a BACKGROUND window, where Chrome throttles
 * timers to roughly one tick a minute -- so an eight-second popup could open
 * and close between two polls. The flags in rig.mjs turn that off.
 *
 * So: find the toast container by its fixed position, take the card inside it,
 * and keep the page around the shot. A popup photographed on its own could be
 * any toast on any site; the point of this one is that it landed on a page the
 * guest was already reading.
 */
async function shotToast(page, name, { waitMs = 30000 } = {}) {
  const found = await page.waitForFunction(() => {
    // react-hot-toast's container is fixed and full-width; the toast is its
    // descendant. Walk down from the container rather than guessing upward.
    const containers = [...document.querySelectorAll("div")].filter((d) => {
      const st = getComputedStyle(d);
      return st.position === "fixed" && Number(st.zIndex) > 1000;
    });
    for (const c of containers) {
      const card = [...c.querySelectorAll("div")].find((d) => {
        const r = d.getBoundingClientRect();
        return r.width > 200 && r.width < 600 && r.height > 50 && r.height < 320
          && /View$/m.test((d.innerText || "").trim());
      });
      if (!card) continue;
      const r = card.getBoundingClientRect();
      window.__toastBox = { x: r.x, y: r.y, width: r.width, height: r.height };
      return true;
    }
    return null;
  }, { timeout: waitMs, polling: 300 }).catch(() => null);

  if (!found) {
    console.log("  ..  no popup appeared; photographing the page as it stood");
    await shot(page, name);
    return false;
  }
  await shot(page, name);                      // the page around it
  const box = await page.evaluate(() => window.__toastBox);
  await shot(page, `${name}-close`, {
    clip: {
      x: Math.max(0, box.x - 14),
      y: Math.max(0, box.y - 14),
      width: Math.min(1400, box.width + 28),
      height: Math.min(1400, box.height + 28),
    },
  });
  return true;
}

const bothScenarios = {
  /**
   * The whole argument, end to end, with the announcement caught in flight.
   *
   *   guest 1,800  -> the platform answers 2,300 in the host's name
   *   guest 1,600  -> under the floor, so it goes to a person
   *   host declines -> the guest's page says so while they are still on it,
   *                    and the host's last price stays on the table for an hour
   */
  async "x1-live-decline"(guest, host) {
    await openListing(guest);
    await offer(guest, 1800, "n2-counter");

    // Counter back, under the floor -- the one move that reaches a person.
    await clickButton(guest, "Counter this price");
    await pause(1200);
    const h = await guest.evaluateHandle(() => {
      const dlg = [...document.querySelectorAll("div")].find((d) => /Your counter, per night/i.test(d.textContent || "") && d.querySelector("input"));
      return dlg?.querySelector("input") || null;
    });
    const el = h.asElement();
    if (!el) throw new Error("counter input not found");
    await el.click({ clickCount: 3 });
    await guest.keyboard.press("Backspace");
    await el.type("1600");
    await shotDialog(guest, "n6-counter-typed");
    await clickButton(guest, "Send to the host");
    await pause(8000);
    await shotDialog(guest, "n6-escalated");

    // The guest's own record, with an answer under every offer.
    await guest.goto(`${SITE}/account/negotiations`, { waitUntil: "domcontentloaded" });
    await pause(7000);
    await dismissBanners(guest);
    await shotFull(guest, "n4-thread");

    // Back to the listing, and STAY there: the popup has to land on a page the
    // guest was already reading, which is the whole point of it.
    await openListing(guest);

    // -- the host's window --------------------------------------------------
    await host.goto(`${SITE}/host/negotiations`, { waitUntil: "domcontentloaded" });
    await pause(7000);
    await dismissBanners(host);
    await shotFull(host, "h1-host-offer");
    await clickExactButton(host, "Decline");

    // -- ...and what the guest sees without touching anything ---------------
    await shotToast(guest, "x1-live-popup");
    await pause(1500);
    await guest.reload({ waitUntil: "domcontentloaded" });
    await pause(6500);
    await dismissBanners(guest);
    await shotRail(guest, "n9-parting");

    await guest.goto(`${SITE}/account/negotiations`, { waitUntil: "domcontentloaded" });
    await pause(7000);
    await shotFull(guest, "n10-thread-declined");

    await host.reload({ waitUntil: "domcontentloaded" });
    await pause(7000);
    await shotFull(host, "h3-host-thread");
  },

  /** A thread that ends in a yes, so the rail can be photographed holding a deal. */
  async "x2-accepted"(guest, host) {
    await openListing(guest);
    await offer(guest, 2400, "n3-accepted");
    await openListing(guest);
    await shotRail(guest, "n3-rail-deal");
    await guest.goto(`${SITE}/account/negotiations`, { waitUntil: "domcontentloaded" });
    await pause(7000);
    await dismissBanners(guest);
    await shotFull(guest, "n4-thread-accepted");
    await openListing(guest);
    // The barred control and the sentence under it, not the whole rail --
    // a full-rail crop here is the same photograph as n3-rail-deal.
    await shotOfferBlock(guest, "n5-already-agreed");

    // The host is TOLD, not asked -- and their own screen marks the words the
    // platform wrote in their name.
    await host.goto(`${SITE}/host/negotiations`, { waitUntil: "domcontentloaded" });
    await pause(7000);
    await dismissBanners(host);
    await shotFull(host, "h4-host-auto-accepted");
  },
};

/* ── run one ──────────────────────────────────────────────────────────────── */

const name = process.argv[2];
const both = bothScenarios[name];
const fn = scenarios[name];

if (!both && !fn) {
  console.log("scenarios:\n  " + Object.keys(scenarios).join("\n  ")
    + "\n\ntwo-browser scenarios:\n  " + Object.keys(bothScenarios).join("\n  "));
  process.exit(1);
}

if (both) {
  // Two profiles, two windows, one story. The guest is left on the page they
  // were reading, so the host's action can arrive in it unannounced.
  const g = await open("renter");
  const h = await open("host");
  try {
    console.log(`\n=== ${name}  (renter + host) ===`);
    await both(g.page, h.page);
    console.log("  done");
  } catch (e) {
    console.error("  FAILED:", e.message);
    await shot(g.page, `FAILED-${name}-renter`).catch(() => {});
    await shot(h.page, `FAILED-${name}-host`).catch(() => {});
    process.exitCode = 1;
  } finally {
    await g.browser.close();
    await h.browser.close();
  }
} else {
  const role = name.startsWith("h") ? "host" : "renter";
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
}
