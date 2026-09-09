// Screenshot rig for the negotiation journey document.
//
// WHY THIS EXISTS. The browser tools available to the assistant return images
// into the conversation but cannot write a file, and a PDF needs files. So the
// shots are taken by a Chrome this script drives directly.
//
// HOW LOGIN WORKS, AND WHY IT IS LIKE THIS. The assistant must never type a
// password. So this runs Chrome VISIBLY against a profile directory that
// persists between runs: the first time, it stops and waits while a person
// signs in by hand; every run after that the session is already in the profile
// and it goes straight through. The password is typed by a human into a real
// browser and never passes through the assistant, the transcript, or this
// file.
//
// Two profiles, because the document needs both sides of every scenario:
//   .chrome/renter   the guest making offers
//   .chrome/host     the host receiving them
//
// Usage:
//   node negotiation-journey/rig.mjs login renter
//   node negotiation-journey/rig.mjs login host
//   node negotiation-journey/rig.mjs shot renter <name> <url> [--full]
//
// The scenario driving lives in journey.mjs; this file is the plumbing.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import puppeteer from "puppeteer-core";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
export const CHROME = "C:/Program Files/Google/Chrome/Application/chrome.exe";
export const SITE = "https://www.aajoohomes.com";
export const SHOTS = path.join(__dirname, "shots");
const PROFILES = path.join(__dirname, ".chrome");

fs.mkdirSync(SHOTS, { recursive: true });

/** Open (or reopen) a browser on a named persistent profile. */
export async function open(role, { headless = false } = {}) {
  const userDataDir = path.join(PROFILES, role);
  fs.mkdirSync(userDataDir, { recursive: true });
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless,
    userDataDir,
    defaultViewport: { width: 1440, height: 900 },
    args: [
      "--no-first-run",
      "--no-default-browser-check",
      "--disable-features=Translate,MediaRouter",
      "--window-size=1460,980",
    ],
  });
  const [page] = await browser.pages();
  page.setDefaultTimeout(45000);
  return { browser, page };
}

/** Is this profile signed in? Checks the account area, which bounces if not. */
export async function signedIn(page) {
  await page.goto(`${SITE}/account/dashboard`, { waitUntil: "domcontentloaded" });
  await new Promise((r) => setTimeout(r, 4000));
  return !/\/(login|signin)?$/.test(new URL(page.url()).pathname) &&
    page.url().includes("/account");
}

/** Wait, visibly, until a person has signed this profile in. */
export async function waitForLogin(page, role) {
  const deadline = Date.now() + 10 * 60 * 1000;
  console.log(`\n  >>> Sign in as the ${role.toUpperCase()} in the Chrome window that just opened.`);
  console.log("      This window keeps its own profile, so this is a one-time step.\n");
  while (Date.now() < deadline) {
    if (await signedIn(page)) {
      console.log(`  OK  ${role} session is live.`);
      return true;
    }
    await new Promise((r) => setTimeout(r, 5000));
  }
  console.log(`  TIMED OUT waiting for the ${role} sign-in.`);
  return false;
}

/** Save a screenshot under shots/, named for the step. */
export async function shot(page, name, { full = false, clip = null } = {}) {
  const file = path.join(SHOTS, `${name}.png`);
  await page.screenshot({ path: file, fullPage: full, ...(clip ? { clip } : {}) });
  const kb = Math.round(fs.statSync(file).size / 1024);
  console.log(`  shot  ${name}.png  (${kb} KB)`);
  return file;
}

/** Click the first element whose visible text matches. */
export async function clickText(page, text, { tag = "*" } = {}) {
  const handle = await page.evaluateHandle((t, g) => {
    const nodes = [...document.querySelectorAll(g)];
    return nodes.find((n) => {
      const own = [...n.childNodes]
        .filter((c) => c.nodeType === 3)
        .map((c) => c.textContent)
        .join("")
        .trim();
      return own === t || (n.innerText || "").trim() === t;
    }) || null;
  }, text, tag);
  const el = handle.asElement();
  if (!el) throw new Error(`no element with text: ${text}`);
  await el.scrollIntoView();
  await new Promise((r) => setTimeout(r, 300));
  await el.click();
  return true;
}

/**
 * Clear the cookie banner, once per profile.
 *
 * It sits across the bottom of every page and would appear in every
 * screenshot in the document. Answered with ONLY ESSENTIAL — the
 * privacy-preserving choice — not "Accept all": this is a browser profile
 * created to take photographs, and there is no reason for it to opt a test
 * account into analytics and marketing tracking.
 */
export async function dismissBanners(page) {
  await page.evaluate(() => {
    const btn = [...document.querySelectorAll("button, a")]
      .find((b) => /only essential/i.test((b.innerText || "").trim()));
    btn?.click();
  }).catch(() => {});
  await new Promise((r) => setTimeout(r, 700));
}

export const pause = (ms) => new Promise((r) => setTimeout(r, ms));

// ── CLI ─────────────────────────────────────────────────────────────────────
if (process.argv[1] && process.argv[1].endsWith("rig.mjs")) {
  const [, , cmd, role, ...rest] = process.argv;
  const { browser, page } = await open(role || "renter");
  if (cmd === "login") {
    const ok = await signedIn(page);
    if (ok) console.log(`  ${role} is already signed in — nothing to do.`);
    else await waitForLogin(page, role);
    await browser.close();
  } else if (cmd === "shot") {
    const [name, url] = rest;
    await page.goto(url.startsWith("http") ? url : SITE + url, { waitUntil: "domcontentloaded" });
    await pause(2500);
    await shot(page, name, { full: rest.includes("--full") });
    await browser.close();
  } else {
    console.log("commands: login <role> | shot <role> <name> <url>");
    await browser.close();
  }
}
