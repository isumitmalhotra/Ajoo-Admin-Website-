# Finance Staging Integration Report

- Date: 2026-03-30T07:57:22.503Z
- Base URL: http://localhost:8000
- Write tests enabled: no

## Summary

- Passed: 0
- Warnings: 0
- Failed: 10
- Skipped: 7
- Total: 17

## Results

| Name | Method | Path | Result | HTTP | Notes |
|------|--------|------|--------|------|-------|
| Ledger search | POST | /admin/finance/ledger/search | FAIL | - | Network error: fetch failed; duration=45ms |
| Payout search | POST | /admin/finance/payout/search | FAIL | - | Network error: fetch failed; duration=2ms |
| Payout schedule search | POST | /admin/finance/payout/schedule/search | FAIL | - | Network error: fetch failed; duration=2ms |
| Invoice search | POST | /admin/finance/invoice/search | FAIL | - | Network error: fetch failed; duration=3ms |
| Reconciliation search | POST | /admin/finance/reconciliation/search | FAIL | - | Network error: fetch failed; duration=2ms |
| Finance dashboard | GET | /admin/finance/dashboard | FAIL | - | Network error: fetch failed; duration=1ms |
| Revenue report | POST | /admin/finance/reports/revenue | FAIL | - | Network error: fetch failed; duration=2ms |
| Commission report | POST | /admin/finance/reports/commission | FAIL | - | Network error: fetch failed; duration=2ms |
| Tax report | POST | /admin/finance/reports/tax | FAIL | - | Network error: fetch failed; duration=2ms |
| Cashflow report | POST | /admin/finance/reports/cashflow | FAIL | - | Network error: fetch failed; duration=3ms |
| Host ledger by id | POST | /admin/finance/ledger/host/{hostId} | SKIP | - | Missing required test ID in environment variables |
| Guest ledger by id | POST | /admin/finance/ledger/user/{userId} | SKIP | - | Missing required test ID in environment variables |
| Ledger detail by id | GET | /admin/finance/ledger/{ledgerId} | SKIP | - | Missing required test ID in environment variables |
| Payout detail by id | GET | /admin/finance/payout/{payoutId} | SKIP | - | Missing required test ID in environment variables |
| Invoice detail by id | GET | /admin/finance/invoice/{invoiceId} | SKIP | - | Missing required test ID in environment variables |
| Invoice download | GET | /admin/finance/invoice/download/{invoiceId} | SKIP | - | Missing required test ID in environment variables |
| Reconciliation detail by id | GET | /admin/finance/reconciliation/{reconId} | SKIP | - | Missing required test ID in environment variables |
