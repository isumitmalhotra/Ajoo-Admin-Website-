#!/usr/bin/env node

/**
 * Finance System Staging Integration Runner
 *
 * Purpose:
 * - Execute live API integration checks against staging backend
 * - Validate core read flows by default (safe mode)
 * - Optionally run write-path checks with explicit opt-in
 * - Generate JSON + Markdown reports for release tracking
 *
 * Usage:
 *   node scripts/financeIntegrationStaging.js
 *   node scripts/financeIntegrationStaging.js --base-url=https://staging.example.com
 *   node scripts/financeIntegrationStaging.js --write-tests
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const DEFAULT_TIMEOUT_MS = 15000;
const WRITE_FLAG = "--write-tests";

function parseEnvContent(content) {
  const parsed = {};
  const lines = content.split(/\r?\n/);

  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;

    const equalIndex = line.indexOf("=");
    if (equalIndex <= 0) continue;

    const key = line.slice(0, equalIndex).trim();
    let value = line.slice(equalIndex + 1).trim();

    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }

    parsed[key] = value;
  }

  return parsed;
}

function loadEnvFiles() {
  const repoRoot = path.join(__dirname, "..");
  const envFiles = [
    ".env",
    ".env.local",
    ".env.staging",
    ".env.staging.local",
  ];

  const loadedFiles = [];

  for (const fileName of envFiles) {
    const fullPath = path.join(repoRoot, fileName);
    if (!fs.existsSync(fullPath)) continue;

    const content = fs.readFileSync(fullPath, "utf8");
    const parsed = parseEnvContent(content);

    for (const [key, value] of Object.entries(parsed)) {
      // Preserve explicitly provided environment variables.
      if (process.env[key] === undefined) {
        process.env[key] = value;
      }
    }

    loadedFiles.push(fileName);
  }

  return loadedFiles;
}

function parseArgs(argv) {
  const parsed = {
    writeTests: false,
    baseUrl: "",
    timeoutMs: DEFAULT_TIMEOUT_MS,
    help: false,
  };

  for (const arg of argv) {
    if (arg === WRITE_FLAG) {
      parsed.writeTests = true;
      continue;
    }

    if (arg === "--help" || arg === "-h") {
      parsed.help = true;
      continue;
    }

    if (arg.startsWith("--base-url=")) {
      parsed.baseUrl = arg.replace("--base-url=", "").trim();
      continue;
    }

    if (arg.startsWith("--timeout=")) {
      const raw = Number(arg.replace("--timeout=", "").trim());
      if (Number.isFinite(raw) && raw > 0) {
        parsed.timeoutMs = raw;
      }
      continue;
    }
  }

  return parsed;
}

function normalizeBaseUrl(url) {
  return url.replace(/\/+$/, "");
}

function formatDuration(ms) {
  return `${ms.toFixed(0)}ms`;
}

function safeJsonParse(raw) {
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function maskToken(token) {
  if (!token) return "none";
  if (token.length <= 10) return "***";
  return `${token.slice(0, 6)}...${token.slice(-4)}`;
}

function renderMarkdownReport(report) {
  const lines = [];
  lines.push("# Finance Staging Integration Report");
  lines.push("");
  lines.push(`- Date: ${report.generatedAt}`);
  lines.push(`- Base URL: ${report.baseUrl}`);
  lines.push(`- Write tests enabled: ${report.writeTestsEnabled ? "yes" : "no"}`);
  lines.push("");
  lines.push("## Summary");
  lines.push("");
  lines.push(`- Passed: ${report.summary.passed}`);
  lines.push(`- Warnings: ${report.summary.warnings}`);
  lines.push(`- Failed: ${report.summary.failed}`);
  lines.push(`- Skipped: ${report.summary.skipped}`);
  lines.push(`- Total: ${report.summary.total}`);
  lines.push("");
  lines.push("## Results");
  lines.push("");
  lines.push("| Name | Method | Path | Result | HTTP | Notes |");
  lines.push("|------|--------|------|--------|------|-------|");

  for (const item of report.results) {
    const httpCode = item.httpStatus === null ? "-" : String(item.httpStatus);
    const notes = item.notes.replace(/\|/g, "\\|");
    lines.push(
      `| ${item.name} | ${item.method} | ${item.path} | ${item.result} | ${httpCode} | ${notes} |`
    );
  }

  return `${lines.join("\n")}\n`;
}

async function runRequest({
  baseUrl,
  endpoint,
  method,
  body,
  token,
  timeoutMs,
}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  const started = Date.now();

  const url = `${baseUrl}${endpoint}`;
  const headers = {
    Accept: "application/json",
  };

  if (body !== undefined) {
    headers["Content-Type"] = "application/json";
  }

  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  try {
    const response = await fetch(url, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
      signal: controller.signal,
    });

    const raw = await response.text();
    const parsed = safeJsonParse(raw);
    const durationMs = Date.now() - started;

    clearTimeout(timeout);

    return {
      ok: response.ok,
      httpStatus: response.status,
      durationMs,
      parsedBody: parsed,
      rawBody: raw,
      networkError: "",
    };
  } catch (error) {
    clearTimeout(timeout);
    const durationMs = Date.now() - started;
    return {
      ok: false,
      httpStatus: null,
      durationMs,
      parsedBody: null,
      rawBody: "",
      networkError: error instanceof Error ? error.message : "Unknown network error",
    };
  }
}

function resolvePath(pathTemplate, ids) {
  let resolved = pathTemplate;
  const tokens = pathTemplate.match(/\{[^}]+\}/g) || [];

  for (const token of tokens) {
    const key = token.slice(1, -1);
    const value = ids[key];
    if (!value) return null;
    resolved = resolved.replace(token, String(value));
  }

  return resolved;
}

function evaluateResult(response, context) {
  const hasToken = Boolean(context.token);

  if (response.httpStatus === null) {
    return {
      result: "FAIL",
      notes: `Network error: ${response.networkError}`,
    };
  }

  if (response.ok) {
    const isJson = response.parsedBody !== null;
    if (!isJson) {
      return {
        result: "WARN",
        notes: `HTTP ${response.httpStatus} but response is not valid JSON`,
      };
    }

    const body = response.parsedBody;
    const hasEnvelope =
      body &&
      typeof body === "object" &&
      ("data" in body || "success" in body || "message" in body);

    return {
      result: hasEnvelope ? "PASS" : "WARN",
      notes: hasEnvelope
        ? `HTTP ${response.httpStatus}, envelope structure detected`
        : `HTTP ${response.httpStatus}, JSON returned without expected envelope keys`,
    };
  }

  if (!hasToken && (response.httpStatus === 401 || response.httpStatus === 403)) {
    return {
      result: "WARN",
      notes: `HTTP ${response.httpStatus}, protected endpoint reachable (token missing)` ,
    };
  }

  const preview = response.rawBody ? response.rawBody.slice(0, 140).replace(/\s+/g, " ") : "no body";

  return {
    result: "FAIL",
    notes: `HTTP ${response.httpStatus}, body preview: ${preview}`,
  };
}

function printUsage() {
  console.log("\nFinance staging integration runner\n");
  console.log("Usage:");
  console.log("  node scripts/financeIntegrationStaging.js");
  console.log("  node scripts/financeIntegrationStaging.js --base-url=https://staging.example.com");
  console.log("  node scripts/financeIntegrationStaging.js --write-tests");
  console.log("  node scripts/financeIntegrationStaging.js --timeout=20000\n");
}

async function main() {
  const loadedEnvFiles = loadEnvFiles();
  const args = parseArgs(process.argv.slice(2));

  if (args.help) {
    printUsage();
    process.exit(0);
  }

  const baseUrlRaw = args.baseUrl || process.env.STAGING_API_BASE_URL || process.env.VITE_API_BASE_URL || "";
  if (!baseUrlRaw) {
    console.error("\nERROR: Missing staging base URL.");
    console.error("Set STAGING_API_BASE_URL (preferred) or VITE_API_BASE_URL.\n");
    process.exit(1);
  }

  const baseUrl = normalizeBaseUrl(baseUrlRaw);
  const token = process.env.STAGING_BEARER_TOKEN || process.env.AUTH_TOKEN || "";

  const ids = {
    hostId: process.env.FINANCE_TEST_HOST_ID || "",
    userId: process.env.FINANCE_TEST_USER_ID || "",
    ledgerId: process.env.FINANCE_TEST_LEDGER_ID || "",
    payoutId: process.env.FINANCE_TEST_PAYOUT_ID || "",
    invoiceId: process.env.FINANCE_TEST_INVOICE_ID || "",
    reconId: process.env.FINANCE_TEST_RECON_ID || "",
    scheduleId: process.env.FINANCE_TEST_SCHEDULE_ID || "",
  };

  const readOnlyTests = [
    {
      name: "Ledger search",
      method: "POST",
      pathTemplate: "/admin/finance/ledger/search",
      body: { page: 1, limit: 10 },
    },
    {
      name: "Payout search",
      method: "POST",
      pathTemplate: "/admin/finance/payout/search",
      body: { page: 1, limit: 10 },
    },
    {
      name: "Payout schedule search",
      method: "POST",
      pathTemplate: "/admin/finance/payout/schedule/search",
      body: { page: 1, limit: 10 },
    },
    {
      name: "Invoice search",
      method: "POST",
      pathTemplate: "/admin/finance/invoice/search",
      body: { page: 1, limit: 10 },
    },
    {
      name: "Reconciliation search",
      method: "POST",
      pathTemplate: "/admin/finance/reconciliation/search",
      body: { page: 1, limit: 10 },
    },
    {
      name: "Finance dashboard",
      method: "GET",
      pathTemplate: "/admin/finance/dashboard",
    },
    {
      name: "Revenue report",
      method: "POST",
      pathTemplate: "/admin/finance/reports/revenue",
      body: { period: "monthly", page: 1, limit: 10 },
    },
    {
      name: "Commission report",
      method: "POST",
      pathTemplate: "/admin/finance/reports/commission",
      body: { period: "monthly", page: 1, limit: 10 },
    },
    {
      name: "Tax report",
      method: "POST",
      pathTemplate: "/admin/finance/reports/tax",
      body: { period: "monthly", page: 1, limit: 10 },
    },
    {
      name: "Cashflow report",
      method: "POST",
      pathTemplate: "/admin/finance/reports/cashflow",
      body: { period: "monthly", page: 1, limit: 10 },
    },
    {
      name: "Host ledger by id",
      method: "POST",
      pathTemplate: "/admin/finance/ledger/host/{hostId}",
      body: { page: 1, limit: 10 },
    },
    {
      name: "Guest ledger by id",
      method: "POST",
      pathTemplate: "/admin/finance/ledger/user/{userId}",
      body: { page: 1, limit: 10 },
    },
    {
      name: "Ledger detail by id",
      method: "GET",
      pathTemplate: "/admin/finance/ledger/{ledgerId}",
    },
    {
      name: "Payout detail by id",
      method: "GET",
      pathTemplate: "/admin/finance/payout/{payoutId}",
    },
    {
      name: "Invoice detail by id",
      method: "GET",
      pathTemplate: "/admin/finance/invoice/{invoiceId}",
    },
    {
      name: "Invoice download",
      method: "GET",
      pathTemplate: "/admin/finance/invoice/download/{invoiceId}",
    },
    {
      name: "Reconciliation detail by id",
      method: "GET",
      pathTemplate: "/admin/finance/reconciliation/{reconId}",
    },
  ];

  const writeTests = [
    {
      name: "Payout approve",
      method: "PUT",
      pathTemplate: "/admin/finance/payout/approve/{payoutId}",
    },
    {
      name: "Payout reject",
      method: "PUT",
      pathTemplate: "/admin/finance/payout/reject/{payoutId}",
      body: { reason: "Integration runner validation" },
    },
    {
      name: "Invoice void",
      method: "POST",
      pathTemplate: "/admin/finance/invoice/void/{invoiceId}",
      body: { reason: "Integration runner validation" },
    },
    {
      name: "Reconciliation resolve",
      method: "POST",
      pathTemplate: "/admin/finance/reconciliation/resolve/{reconId}",
      body: { action: "MARK_MATCHED", note: "Integration runner validation" },
    },
    {
      name: "Reconciliation run",
      method: "POST",
      pathTemplate: "/admin/finance/reconciliation/run",
      body: { force: false },
    },
    {
      name: "Payout schedule update",
      method: "PUT",
      pathTemplate: "/admin/finance/payout/schedule/update/{scheduleId}",
      body: { isActive: true },
    },
  ];

  const tests = args.writeTests ? [...readOnlyTests, ...writeTests] : readOnlyTests;

  console.log("\n==============================================================");
  console.log("FINANCE STAGING INTEGRATION RUNNER");
  console.log("==============================================================");
  console.log(`Base URL:              ${baseUrl}`);
  console.log(`Write tests enabled:   ${args.writeTests ? "yes" : "no"}`);
  console.log(`Bearer token:          ${maskToken(token)}`);
  console.log(`Timeout per request:   ${args.timeoutMs}ms`);
  console.log(`Total planned tests:   ${tests.length}`);
  console.log(
    `Loaded env files:      ${loadedEnvFiles.length > 0 ? loadedEnvFiles.join(", ") : "none"}`
  );

  const results = [];

  for (const test of tests) {
    const resolvedPath = resolvePath(test.pathTemplate, ids);

    if (!resolvedPath) {
      results.push({
        name: test.name,
        method: test.method,
        path: test.pathTemplate,
        result: "SKIP",
        httpStatus: null,
        durationMs: 0,
        notes: "Missing required test ID in environment variables",
      });
      continue;
    }

    const response = await runRequest({
      baseUrl,
      endpoint: resolvedPath,
      method: test.method,
      body: test.body,
      token,
      timeoutMs: args.timeoutMs,
    });

    const evaluated = evaluateResult(response, { token });

    results.push({
      name: test.name,
      method: test.method,
      path: resolvedPath,
      result: evaluated.result,
      httpStatus: response.httpStatus,
      durationMs: response.durationMs,
      notes: `${evaluated.notes}; duration=${formatDuration(response.durationMs)}`,
    });
  }

  const summary = {
    passed: results.filter((r) => r.result === "PASS").length,
    warnings: results.filter((r) => r.result === "WARN").length,
    failed: results.filter((r) => r.result === "FAIL").length,
    skipped: results.filter((r) => r.result === "SKIP").length,
    total: results.length,
  };

  console.log("\nResults:");
  for (const r of results) {
    const status = r.httpStatus === null ? "-" : String(r.httpStatus);
    console.log(
      `  [${r.result}] ${r.method.padEnd(4)} ${r.path.padEnd(48)} status=${status.padEnd(3)} ${formatDuration(r.durationMs)}`
    );
  }

  console.log("\nSummary:");
  console.log(`  PASS: ${summary.passed}`);
  console.log(`  WARN: ${summary.warnings}`);
  console.log(`  FAIL: ${summary.failed}`);
  console.log(`  SKIP: ${summary.skipped}`);
  console.log(`  TOTAL: ${summary.total}`);

  const report = {
    generatedAt: new Date().toISOString(),
    baseUrl,
    writeTestsEnabled: args.writeTests,
    timeoutMs: args.timeoutMs,
    summary,
    results,
  };

  const reportsDir = path.join(__dirname, "../reports");
  fs.mkdirSync(reportsDir, { recursive: true });

  const jsonPath = path.join(reportsDir, "finance-integration-report.json");
  const mdPath = path.join(reportsDir, "finance-integration-report.md");

  fs.writeFileSync(jsonPath, `${JSON.stringify(report, null, 2)}\n`, "utf8");
  fs.writeFileSync(mdPath, renderMarkdownReport(report), "utf8");

  console.log("\nArtifacts:");
  console.log(`  JSON report: ${jsonPath}`);
  console.log(`  MD report:   ${mdPath}`);

  if (summary.failed > 0) {
    console.log("\nIntegration runner finished with failures.");
    process.exit(1);
  }

  console.log("\nIntegration runner finished successfully.");
  process.exit(0);
}

main();
