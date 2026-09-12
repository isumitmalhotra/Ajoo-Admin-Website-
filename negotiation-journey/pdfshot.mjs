// Photograph pages of the built PDF, so the document can be eyeballed before
// it goes to the client.
//
// Chrome's own PDF viewer is the renderer — no poppler, no ImageMagick, and it
// is the same engine that produced the file, so what this shows is what the
// client will open.
//
//   node negotiation-journey/pdfshot.mjs 1 2 3
//
// The files it writes (shots/pdf-pNN.png) are throwaway: they are proofs of
// the document, not photographs in it. Delete them before committing.
import path from "node:path";
import { fileURLToPath } from "node:url";
import { open, shot, pause } from "./rig.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PDF = path.join(__dirname, "Aajoo-Negotiation-User-Journey.pdf");
const pages = process.argv.slice(2).map(Number).filter((n) => n > 0);
if (!pages.length) pages.push(1);

const { browser, page } = await open("renter");
try {
  await page.setViewport({ width: 1100, height: 1450 });
  // Chrome's viewer only honours #page=N on a FRESH load of that URL — asking
  // for the same file twice in a row leaves it wherever it was, which is how
  // the first run produced two photographs of page one. Reload between pages.
  for (const n of pages) {
    await page.goto("about:blank");
    await pause(300);
    await page.goto(`file:///${PDF.replace(/\\/g, "/")}#page=${n}&toolbar=0&view=FitH`, {
      waitUntil: "domcontentloaded",
    });
    await pause(5000);
    await shot(page, `pdf-p${String(n).padStart(2, "0")}`);
  }
} finally {
  await browser.close();
}
