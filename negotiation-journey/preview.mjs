// Photograph the generated HTML so the layout can be checked without a PDF
// renderer on this machine.
import puppeteer from "puppeteer-core";
import { CHROME, SHOTS } from "./rig.mjs";
import path from "node:path";

const html = "file:///" + "D:/Projects/ajoo admin website/negotiation-journey/Aajoo-Negotiation-User-Journey.html";
const browser = await puppeteer.launch({ executablePath: CHROME, headless: "new", defaultViewport: { width: 820, height: 1160 } });
const page = await browser.newPage();
await page.goto(html, { waitUntil: "networkidle0" });
for (const [i, y] of [0, 1100, 2400, 3800].entries()) {
  await page.evaluate((yy) => window.scrollTo(0, yy), y);
  await new Promise((r) => setTimeout(r, 500));
  await page.screenshot({ path: path.join(SHOTS, `pdf-preview-${i}.png`) });
}
const h = await page.evaluate(() => document.body.scrollHeight);
console.log("document height:", h, "px  (~", Math.ceil(h / 1120), "pages )");
await browser.close();
