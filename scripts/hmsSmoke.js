#!/usr/bin/env node
/**
 * Host Management System (HMS) — HTTP Smoke Runner
 * Sprint: Full Delivery 2026-06-09..18 (A-08)
 *
 * Probes 16 host-portal endpoints + 8 admin-side endpoints = 24 total.
 *
 * Usage:
 *   node scripts/hmsSmoke.js                                          # default localhost:8080
 *   HMS_BASE_URL=https://aajaodev.onrender.com node scripts/hmsSmoke.js
 *   HMS_BASE_URL=... HOST_JWT=... ADMIN_JWT=... node scripts/hmsSmoke.js
 *
 * Exit 0 = all green, 1 = any failure.
 */

const BASE = process.env.HMS_BASE_URL || "http://localhost:8080";
const HOST_JWT = process.env.HOST_JWT || null;
const ADMIN_JWT = process.env.ADMIN_JWT || null;
const TIMEOUT_MS = 8000;

const hostEndpoints = [
    { method: "GET",  path: "/host/dashboard/summary" },
    { method: "POST", path: "/host/bookings/search", body: { page: 1, limit: 5 } },
    { method: "GET",  path: "/host/bookings/detail/1" },
    { method: "GET",  path: "/host/earnings/summary" },
    { method: "GET",  path: "/host/payout/history?page=1&limit=5" },
    { method: "GET",  path: "/host/profile/get" },
    { method: "PUT",  path: "/host/profile/update", body: { fullName: "Smoke Test" } },
    { method: "GET",  path: "/host/payout-account/get" },
    { method: "PUT",  path: "/host/payout-account/update", body: { upiId: "test@upi" } },
    { method: "POST", path: "/host/statements/search", body: { page: 1, limit: 5 } },
    { method: "GET",  path: "/host/statements/download/2026-06" },
    { method: "POST", path: "/host/support/tickets/search", body: { page: 1, limit: 5 } },
    { method: "POST", path: "/host/support/tickets/create", body: { subject: "smoke", category: "GENERAL", message: "smoke test message body" } },
    { method: "POST", path: "/host/support/tickets/reply", body: { ticketId: 1, message: "smoke reply" } },
    { method: "GET",  path: "/host/performance/summary" },
    { method: "POST", path: "/host/onboarding/submit", body: {
        propertyType: "Villa", city: "Goa", state: "Goa", country: "India",
        hostingExperience: "5+ years", contactName: "Smoke", contactPhone: "9876543210", message: "smoke onboarding"
    }, role: "user" }, // onboarding uses authenticateJWT, not hostAuthentication
];

const adminEndpoints = [
    { method: "GET",  path: "/admin/host/detail/1" },
    { method: "GET",  path: "/admin/host/kyc/detail/1" },
    { method: "POST", path: "/admin/host/kyc/approve", body: { hostId: 1, note: "smoke" } },
    { method: "POST", path: "/admin/host/kyc/reject", body: { hostId: 1, reason: "smoke test reject" } },
    { method: "GET",  path: "/admin/host/performance/summary?hostId=1" },
    { method: "GET",  path: "/admin/host/payout/history?hostId=1&page=1&limit=5" },
    { method: "POST", path: "/admin/host/payout/hold", body: { hostId: 1, reason: "smoke hold test" } },
    { method: "POST", path: "/admin/host/payout/release", body: { hostId: 1, note: "smoke release" } },
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

const probe = async (ep, jwt) => {
    const url = `${BASE}${ep.path}`;
    const headers = { "Content-Type": "application/json" };
    if (jwt) headers["Authorization"] = `Bearer ${jwt}`;
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

    let ok = false, why = "";
    if (status === 401) { ok = true; why = "auth required (route mounted)"; }
    else if (jwt && (status === 200 || status === 201)) { ok = true; why = "ok"; }
    else if (jwt && (status === 400 || status === 422)) { ok = true; why = "validated (route exists)"; }
    else if (status === 404 && !jwt) { ok = false; why = "404 — endpoint not mounted"; }
    else if (status === 404) { ok = true; why = "404 — route ran, record id not found (expected for id=1)"; }
    else if (status >= 500) { ok = false; why = `${status} — SERVER ERROR (real bug — paste this line to fix)`; }
    else if (status === 400 || status === 422) { ok = true; why = "400/422 — route exists, body invalid (expected without JWT)"; }
    else { ok = true; why = `status ${status}`; }
    return { ep, status, ok, why };
};

(async () => {
    console.log(colors.bold(`\nHMS Smoke Runner`));
    console.log(colors.gray(`Base URL: ${BASE}`));
    console.log(colors.gray(`HOST JWT: ${HOST_JWT ? "supplied" : colors.yellow("NOT supplied")}`));
    console.log(colors.gray(`ADMIN JWT: ${ADMIN_JWT ? "supplied" : colors.yellow("NOT supplied")}`));
    console.log(colors.gray(`Endpoints: ${hostEndpoints.length + adminEndpoints.length} (${hostEndpoints.length} host + ${adminEndpoints.length} admin)`));
    console.log("");

    const results = [];

    console.log(colors.bold("Host portal endpoints:"));
    for (const ep of hostEndpoints) {
        const r = await probe(ep, HOST_JWT);
        results.push(r);
        const mark = r.ok ? colors.green("✓") : colors.red("✗");
        const statusStr = r.status === null ? colors.red("ERR") : (r.ok ? colors.gray(`${r.status}`) : colors.red(`${r.status}`));
        console.log(`  ${mark} ${ep.method.padEnd(4)} ${ep.path.padEnd(55)} ${statusStr}  ${colors.gray(r.why)}`);
    }

    console.log("");
    console.log(colors.bold("Admin endpoints:"));
    for (const ep of adminEndpoints) {
        const r = await probe(ep, ADMIN_JWT);
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
