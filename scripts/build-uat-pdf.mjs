// Markdown -> styled HTML -> PDF, using the Chrome already installed on this
// machine. Kept as a script rather than a one-liner so the document can be
// regenerated after an edit without rebuilding the pipeline.
import fs from "node:fs";
import path from "node:path";
import { marked } from "marked";
import puppeteer from "puppeteer-core";

const SRC = process.argv[2];
const OUT = process.argv[3];
const CHROME = "C:/Program Files/Google/Chrome/Application/chrome.exe";

const md = fs.readFileSync(SRC, "utf8");

// The first H1 becomes the cover title rather than a body heading.
const titleMatch = md.match(/^#\s+(.+)$/m);
const title = titleMatch ? titleMatch[1].trim() : path.basename(SRC);
const body = md.replace(/^#\s+.+$/m, "").replace(/^\s*---\s*$/m, "");

marked.setOptions({ gfm: true, breaks: false });
const html = marked.parse(body);

const page = `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>${title}</title>
<style>
  @page { size: A4; margin: 20mm 17mm 22mm; }

  :root {
    --navy: #1B2447;
    --teal: #0F766E;
    --ink:  #1F2937;
    --muted:#5B6472;
    --line: #D9DEE7;
    --soft: #F4F6F9;
  }

  * { box-sizing: border-box; }

  body {
    background: #fff;
    /* Cambria before Georgia deliberately: Georgia ships OLD-STYLE figures, so
       "six P0s" reads as "six Pos" and every number sits at a different
       height. This document is full of IDs and money. Cambria has lining
       figures and prints just as well. */
    font-family: Cambria, "Palatino Linotype", Georgia, "Times New Roman", serif;
    font-variant-numeric: lining-nums;
    font-size: 10.4pt;
    line-height: 1.58;
    color: var(--ink);
    margin: 0;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }

  /* ---- cover ------------------------------------------------------- */
  .cover { page-break-after: always; padding-top: 58mm; }
  .cover .rule { width: 54px; height: 4px; background: var(--teal); margin-bottom: 22px; }
  .cover h1 {
    font-family: "Segoe UI Semibold", "Segoe UI", Calibri, sans-serif;
    font-size: 27pt; line-height: 1.2; color: var(--navy);
    margin: 0 0 16px; font-weight: 600; letter-spacing: -0.4px;
  }
  .cover .sub { font-size: 11.5pt; color: var(--muted); margin: 0 0 40px; max-width: 118mm; }
  .cover .meta {
    font-family: "Segoe UI", Calibri, sans-serif; font-size: 9pt;
    color: var(--muted); border-top: 1px solid var(--line); padding-top: 12px;
  }
  .cover .meta strong { color: var(--navy); font-weight: 600; }

  /* ---- headings ---------------------------------------------------- */
  h2, h3, h4 {
    font-family: "Segoe UI Semibold", "Segoe UI", Calibri, sans-serif;
    color: var(--navy); font-weight: 600; page-break-after: avoid;
  }
  h2 {
    font-size: 15pt; margin: 26px 0 12px; padding-bottom: 6px;
    border-bottom: 1.5px solid var(--line); letter-spacing: -0.2px;
  }
  h3 {
    font-size: 11.4pt; margin: 18px 0 7px; color: var(--teal);
    letter-spacing: .1px;
  }
  h4 { font-size: 10.6pt; margin: 14px 0 6px; }

  p { margin: 0 0 10px; orphans: 3; widows: 3; }

  /* ---- lists ------------------------------------------------------- */
  ul, ol { margin: 0 0 11px; padding-left: 20px; }
  li { margin-bottom: 5px; }
  li > ul, li > ol { margin-top: 5px; }

  /* ---- emphasis & code --------------------------------------------- */
  strong { color: var(--navy); font-weight: 700; }
  code {
    font-family: Consolas, "Courier New", monospace;
    font-size: 8.7pt; background: var(--soft);
    border: 1px solid var(--line); border-radius: 3px;
    padding: 0.5px 4px; color: #33405A;
    /* long identifiers must not push the page sideways */
    word-break: break-word;
  }
  pre { background: var(--soft); border: 1px solid var(--line); border-radius: 5px;
        padding: 10px 12px; overflow-x: auto; page-break-inside: avoid; }
  pre code { border: 0; background: none; padding: 0; font-size: 8.6pt; }

  /* ---- tables ------------------------------------------------------ */
  table {
    width: 100%; border-collapse: collapse; margin: 12px 0 16px;
    font-family: "Segoe UI", Calibri, sans-serif; font-size: 8.7pt;
    page-break-inside: auto;
  }
  thead { display: table-header-group; }   /* repeat header across pages */
  tr { page-break-inside: avoid; page-break-after: auto; }
  th {
    background: var(--navy); color: #fff; text-align: left; font-weight: 600;
    padding: 7px 9px; border: 1px solid var(--navy); line-height: 1.35;
  }
  td {
    padding: 6px 9px; border: 1px solid var(--line); vertical-align: top;
    line-height: 1.45;
  }
  tbody tr:nth-child(even) td { background: #FAFBFD; }
  td code { font-size: 8.1pt; }

  /* ---- callouts ---------------------------------------------------- */
  blockquote {
    margin: 14px 0; padding: 10px 14px;
    background: #F2F8F7; border-left: 3px solid var(--teal);
    page-break-inside: avoid;
  }
  blockquote p { margin: 0 0 6px; }
  blockquote p:last-child { margin-bottom: 0; }

  hr { border: 0; border-top: 1px solid var(--line); margin: 24px 0; }

  /* Keep a section heading with the text that follows it. */
  h2 + p, h3 + p, h2 + table, h3 + table, h2 + ul, h3 + ul { page-break-before: avoid; }
</style></head>
<body>
  <section class="cover">
    <div class="rule"></div>
    <h1>${title}</h1>
    <p class="sub">Developer setup for the controlled UAT run — every record section 4 of the Execution Pack asks for, the defects found while preparing them, and what remains open.</p>
    <div class="meta">
      <strong>Aajoo Homes &mdash; BotPenguin controlled UAT</strong><br>
      Prepared 5 September 2026 by the Zyphex Tech development team<br>
      Verified against the live development backend
    </div>
  </section>
  ${html}
</body></html>`;

const htmlPath = OUT.replace(/\.pdf$/i, ".html");
fs.writeFileSync(htmlPath, page, "utf8");

const browser = await puppeteer.launch({
  executablePath: CHROME,
  headless: "new",
  args: ["--no-sandbox", "--disable-gpu"],
});
const tab = await browser.newPage();
await tab.goto("file:///" + htmlPath.replace(/\\/g, "/"), { waitUntil: "networkidle0" });

const foot = `
  <div style="width:100%;font-family:'Segoe UI',Calibri,sans-serif;font-size:7.5pt;
              color:#8A93A2;padding:0 17mm;display:flex;justify-content:space-between;">
    <span>Aajoo Homes &mdash; BotPenguin UAT: developer setup</span>
    <span>Page <span class="pageNumber"></span> of <span class="totalPages"></span></span>
  </div>`;

await tab.pdf({
  path: OUT,
  format: "A4",
  printBackground: true,
  displayHeaderFooter: true,
  headerTemplate: '<div style="height:0"></div>',
  footerTemplate: foot,
  margin: { top: "20mm", bottom: "22mm", left: "17mm", right: "17mm" },
});

await browser.close();
console.log("WROTE " + OUT);
console.log("bytes " + fs.statSync(OUT).size);
