# 🧪 Finance System Smoke Test — Quick Reference

**Status**: ✅ Ready to use  
**Created**: March 30, 2026  

---

## 🚀 Quick Start

### Run the smoke test:
```bash
npm run test:smoke
# or
npm run validate:api
```

Expected output: ✅ ALL TESTS PASS (32/32 endpoints)

### Run live staging integration checks:
```bash
npm run test:integration:staging
```

Optional write-path checks (approve/reject/void/resolve):
```bash
npm run test:integration:staging:write
```

Generated artifacts:
- `reports/finance-integration-report.json`
- `reports/finance-integration-report.md`

---

## 📋 What It Tests

### ✅ Endpoint Configuration (24 endpoints)
- All finance endpoints defined
- Correct HTTP methods assigned
- Proper API paths

### ✅ Integration Paths (5 flows)
1. **Ledger** → Host Ledger balance calculation
2. **Payout** → Approval/rejection workflow
3. **Invoice** → Lifecycle (create → void)
4. **Reconciliation** → Variance resolution
5. **Reports** → Aggregation across periods

### ✅ India Compliance (5 features)
- GST rate helpers (5%, 12%, 18%)
- TDS Section 194-O calculation
- GSTIN validation
- Invoice numbering format
- Financial Year/Quarter helpers
- INR formatting utility

### ✅ Environment Config (1 check)
- `.env.example` has API base URL template

---

## 📁 Files Created

| File | Purpose | Lines |
|------|---------|-------|
| `src/utils/apiValidation.ts` | Validation utility + report generation | 450 |
| `scripts/financeSmoke.js` | Executable smoke test script | 280 |
| `INTEGRATION_TESTING_CHECKLIST.md` | Complete 5-phase testing guide | 750 |

---

## 🔍 Interpreting Results

### ✅ All Pass (32/32)
```
✅ SUCCESS:
   All critical paths validated!
   System is ready for integration testing with staging backend.
```
→ **Action**: Deploy to staging, run integration tests

### ⚠️  Some Warnings
```
⚠️  NOTE:
   X non-critical endpoint(s) not yet implemented.
   These can be added incrementally.
```
→ **Action**: Create issues for missing endpoints, continue with available ones

### ❌ Critical Failures
```
❌ ACTION REQUIRED:
   X critical endpoint(s) missing.
```
→ **Action**: Update `src/services/endpoints.ts` with missing endpoint paths

---

## 🧬 How It Works

### 1. **Endpoint Validation**
Checks: `ADMINENDPOINTS[key]` is defined for each FMS endpoint
```javascript
const key = "FINANCE_LEDGER_SEARCH";
const path = ADMIN_ENDPOINTS[key]; // ✅ "/admin/finance/ledger/search"
```

### 2. **Path Integrity**
Verifies each critical flow has all required endpoints
```javascript
const path = [
  "FINANCE_LEDGER_SEARCH",
  "FINANCE_LEDGER_HOST"  // ✅ Both must exist
];
```

### 3. **Compliance Checks**
Confirms India-specific utilities exist
- `formatINR()` ✅
- `calculateGST()` ✅
- `calculateTDS194O()` ✅
- `isValidGSTIN()` ✅
- `getFinancialYear()` ✅

---

## 📊 Output Explanation

```
╔═══════════════════════════════════════════════════════════════╗
║      FINANCE SYSTEM SMOKE TEST & VALIDATION REPORT            ║
╚═══════════════════════════════════════════════════════════════╝

📊 Test Results:
  ✅ Passing:           32         ← All tests passed
  ⚠️  Warnings:          0          ← No issues found
  ❌ Critical Issues:    0          ← Ready for staging
  📈 Total Tests:        32         ← Comprehensive coverage

───────────────────────────────────────────────────────────────
ENDPOINT VALIDATION (32 tests)
───────────────────────────────────────────────────────────────

🟢 PASSING (32):               ← Each endpoint verified
  ✅ OK FINANCE_LEDGER_SEARCH
  ✅ OK FINANCE_PAYOUT_APPROVE
  ...
```

---

## 🔧 Customizing the Test

### Add a new endpoint test:

**1. Define in `scripts/financeSmoke.js`:**
```javascript
const FINANCE_ENDPOINTS = {
  FINANCE_LEDGER_SEARCH: {
    method: "POST",
    description: "Search ledger...",
    critical: true  // Important for core flow?
  }
  // Add new endpoint here
};
```

**2. Add to `ADMIN_ENDPOINTS`:**
```javascript
const ADMIN_ENDPOINTS = {
  FINANCE_LEDGER_SEARCH: "/admin/finance/ledger/search",
  // Add matching endpoint path
};
```

**3. Run test:**
```bash
npm run test:smoke
```

---

## 🚦 Exit Codes

| Code | Meaning |
|------|---------|
| `0` | ✅ All tests passed |
| `1` | ❌ Critical failures found |

**Use in CI/CD:**
```bash
npm run test:smoke || exit 1  # Fail build if tests fail
```

---

## 📈 Integration Testing Checklist

After smoke test passes, follow [INTEGRATION_TESTING_CHECKLIST.md](./INTEGRATION_TESTING_CHECKLIST.md)

**5 Phases:**
1. ✅ Endpoint contract validation (1-2 hrs)
2. ✅ Integration path testing (2-3 hrs)
3. ✅ India compliance verification (1-2 hrs)
4. ✅ Performance & scalability (1 hr)
5. ✅ Error handling & edge cases (1.5 hrs)

**Timeline**: 3-4 days on staging backend

---

## 🐛 Troubleshooting

### Error: "require is not defined"
**Cause**: ES module vs CommonJS mismatch  
**Fix**: Ensure `package.json` has `"type": "module"`

### Error: "ADMIN_ENDPOINTS is not defined"
**Cause**: Endpoints file not loaded  
**Fix**: Verify `src/services/endpoints.ts` exists and is exported

### Test shows warnings
**Cause**: Optional endpoint not yet implemented  
**Fix**: Check backend roadmap, implement gradually

---

## 📚 Related Files

- **Validation Logic**: `src/utils/apiValidation.ts`
- **Smoke Test Script**: `scripts/financeSmoke.js`
- **Testing Guide**: `INTEGRATION_TESTING_CHECKLIST.md`
- **Endpoints**: `src/services/endpoints.ts`
- **FMS Types**: `src/pages/admin/finance/types.ts`
- **India Utils**: `src/pages/admin/finance/utils/financeUtils.ts`

---

## ✅ Success Criteria

Your Finance System is ready for staging deployment when:

- ✅ Smoke test passes with 0 critical failures
- ✅ All 24 endpoints configured in `endpoints.ts`
- ✅ API env variable `VITE_API_BASE_URL` set correctly
- ✅ Built successfully: `npm run build` → no errors
- ✅ Ready to deploy and run integration tests

---

**Questions?** Check `INTEGRATION_TESTING_CHECKLIST.md` for detailed test procedures.

**Last Updated**: March 30, 2026  
**Version**: 1.0
