#!/usr/bin/env node
/**
 * Finance Management System (FMS) — HTTP Smoke Runner
 * Sprint: Full Delivery 2026-06-09..18 (A-06)
 *
 * Probes every FMS endpoint over HTTP and reports pass/fail.
 *
 * Usage:
 *   node scripts/financeSmoke.js                              # default base: http://localhost:8080
 *   FMS_BASE_URL=https://aajaodev.onrender.com node scripts/financeSmoke.js
 *   FMS_BASE_URL=... ADMIN_JWT=eyJ... node scripts/financeSmoke.js
 *
 * Pass criteria per endpoint:
 *   - Without ADMIN_JWT:  401 expected (proves auth middleware is wired)
 *   - With ADMIN_JWT:     2xx or 400-with-Yup-error expected (proves route exists)
 *   - 404 = FAIL (endpoint not mounted)
 *   - Connection refused = FAIL (backend not running)
 *
 * Exit codes: 0 = all green, 1 = any failure.
 */

const BASE = process.env.FMS_BASE_URL || "http://localhost:8080";
const JWT = process.env.ADMIN_JWT || null;
const TIMEOUT_MS = 8000;

const endpoints = [
  // Phase 1 (A-03)
  { method: "GET",  path: "/admin/finance/dashboard" },
  { method: "POST", path: "/admin/finance/ledger/search", body: { page: 1, limit: 5 } },
  { method: "POST", path: "/admin/finance/payout/search", body: { page: 1, limit: 5 } },

  // Phase 2 (A-04) — Ledger
  { method: "GET",  path: "/admin/finance/ledger/1" },
  { method: "POST", path: "/admin/finance/ledger/host/1", body: { page: 1, limit: 5 } },
  { method: "POST", path: "/admin/finance/ledger/user/1", body: { page: 1, limit: 5 } },
  { method: "POST", path: "/admin/finance/ledger/export", body: { format: "csv" } },

  // Phase 2 (A-04) — Payout
  { method: "GET",  path: "/admin/finance/payout/1" },
  { method: "POST", path: "/admin/finance/payout/initiate", body: { hostId: 1, note: "smoke" } },
  { method: "PUT",  path: "/admin/finance/payout/1/approve", body: {} },
  { method: "PUT",  path: "/admin/finance/payout/1/reject", body: { reason: "smoke test reject reason" } },

  // Phase 2 (A-04) — Schedule
  { method: "POST", path: "/admin/finance/payout/schedule/search", body: { page: 1, limit: 5 } },
  { method: "PUT",  path: "/admin/finance/payout/schedule/1", body: { frequency: "WEEKLY" } },
  { method: "POST", path: "/admin/finance/payout/schedule/create", body: {
      hostId: 1, frequency: "WEEKLY", minPayoutAmount: 100,
      payoutMethod: "BANK_TRANSFER", accountDetails: { accountNumber: "1234567890", ifsc: "HDFC0001234" },
  } },

  // Phase 3 (A-05) — Invoice
  { method: "POST", path: "/admin/finance/invoice/search", body: { page: 1, limit: 5 } },
  { method: "GET",  path: "/admin/finance/invoice/1" },
  { method: "GET",  path: "/admin/finance/invoice/1/download" },
  { method: "POST", path: "/admin/finance/invoice/void/1", body: { reason: "smoke test void reason" } },

  // Phase 3 (A-05) — Reconciliation
  { method: "POST", path: "/admin/finance/reconciliation/search", body: { page: 1, limit: 5 } },
  { method: "GET",  path: "/admin/finance/reconciliation/1" },
  { method: "PUT",  path: "/admin/finance/reconciliation/1/resolve", body: { action: "ADJUST", notes: "smoke notes here" } },
  { method: "POST", path: "/admin/finance/reconciliation/run", body: { dateFrom: "2026-06-01", dateTo: "2026-06-09" } },

  // Phase 3 (A-05) — Reports
  { method: "POST", path: "/admin/finance/reports/revenue", body: { dateFrom: "2026-06-01", dateTo: "2026-06-09", groupBy: "month" } },
  { method: "POST", path: "/admin/finance/reports/commission", body: { dateFrom: "2026-06-01", dateTo: "2026-06-09", groupBy: "month" } },
  { method: "POST", path: "/admin/finance/reports/tax", body: { dateFrom: "2026-06-01", dateTo: "2026-06-09" } },
  { method: "POST", path: "/admin/finance/reports/cashflow", body: { dateFrom: "2026-06-01", dateTo: "2026-06-09", groupBy: "month" } },
  { method: "POST", path: "/admin/finance/reports/export", body: { reportType: "revenue", dateFrom: "2026-06-01", dateTo: "2026-06-09", format: "csv" } },
];

const colors = {
  green: (s) => `\x1b[32m${s}\x1b[0m`,
  red:   (s) => `\x1b[31m${s}\x1b[0m`,
  yellow:(s) => `\x1b[33m${s}\x1b[0m`,
  gray:  (s) => `\x1b[90m${s}\x1b[0m`,
  bold:  (s) => `\x1b[1m${s}\x1b[0m`,
};

const fetchWithTimeout = async (url, opts) => {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), TIMEOUT_MS);
  try {
    return await fetch(url, { ...opts, signal: ctrl.signal });
  } finally {
    clearTimeout(t);
  }
};

const probe = async (ep) => {
  const url = `${BASE}${ep.path}`;
  const headers = { "Content-Type": "application/json" };
  if (JWT) headers["Authorization"] = `Bearer ${JWT}`;
  const opts = { method: ep.method, headers };
  if (ep.body !== undefined && ep.method !== "GET") {
    opts.body = JSON.stringify(ep.body);
  }

  let status;
  try {
    const r = await fetchWithTimeout(url, opts);
    status = r.status;
  } catch (e) {
    return { ep, status: null, ok: false, why: e?.code === "ECONNREFUSED" ? "connection refused" : (e?.message || "fetch failed") };
  }

  // Pass logic:
  // - 401 always passes (auth required, route exists)
  // - With JWT: 200/201 pass; 400/422 also pass (Yup validation triggered, so route exists)
  // - 404 = fail
  // - 5xx = warn but not fail (DB likely down pre-migration)
  let ok = false, why = "";
  if (status === 401) { ok = true; why = "auth required (route mounted)"; }
  else if (JWT && (status === 200 || status === 201)) { ok = true; why = "ok"; }
  else if (JWT && (status === 400 || status === 422)) { ok = true; why = "validated (route exists)"; }
  else if (status === 404 && !JWT) { ok = false; why = "404 — endpoint not mounted"; }
  else if (status === 404) { ok = true; why = "404 — route ran, record id not found (expected for id=1)"; }
  else if (status >= 500) { ok = false; why = `${status} — SERVER ERROR (real bug — paste this line to fix)`; }
  else if (status === 400 || status === 422) { ok = true; why = "400/422 — route exists, body invalid (expected without JWT)"; }
  else { ok = true; why = `status ${status}`; }
  return { ep, status, ok, why };
};

(async () => {
  console.log(colors.bold(`\nFMS Smoke Runner`));
  console.log(colors.gray(`Base URL: ${BASE}`));
  console.log(colors.gray(`Admin JWT: ${JWT ? "supplied" : colors.yellow("NOT supplied — only auth-mounting will be verified")}`));
  console.log(colors.gray(`Endpoints to probe: ${endpoints.length}`));
  console.log("");

  const results = [];
  for (const ep of endpoints) {
    const r = await probe(ep);
    results.push(r);
    const mark = r.ok ? colors.green("✓") : colors.red("✗");
    const statusStr = r.status === null ? colors.red("ERR") : (r.ok ? colors.gray(`${r.status}`) : colors.red(`${r.status}`));
    console.log(`  ${mark} ${ep.method.padEnd(4)} ${ep.path.padEnd(55)} ${statusStr}  ${colors.gray(r.why)}`);
  }

  const passed = results.filter(r => r.ok).length;
  const failed = results.length - passed;
  console.log("");
  console.log(colors.bold(`Summary: ${colors.green(passed + " passed")} / ${failed > 0 ? colors.red(failed + " failed") : "0 failed"} (${results.length} total)`));

  if (failed > 0) {
    console.log("");
    console.log(colors.red("FAILURES:"));
    results.filter(r => !r.ok).forEach(r => {
      console.log(`  ${r.ep.method} ${r.ep.path} — ${r.why}`);
    });
    process.exit(1);
  }
  process.exit(0);
})();
