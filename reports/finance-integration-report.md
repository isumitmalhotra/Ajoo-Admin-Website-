# Finance Staging Integration Report

- Date: 2026-04-20T08:49:54.122Z
- Base URL: https://aajaodev.onrender.com
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
| Ledger search | POST | /admin/finance/ledger/search | FAIL | 404 | HTTP 404, body preview: <!DOCTYPE html> <html lang="en"> <head> <meta charset="utf-8"> <title>Error</title> </head> <body> <pre>Cannot POST /admin/finance/ledger/se; duration=940ms |
| Payout search | POST | /admin/finance/payout/search | FAIL | 404 | HTTP 404, body preview: <!DOCTYPE html> <html lang="en"> <head> <meta charset="utf-8"> <title>Error</title> </head> <body> <pre>Cannot POST /admin/finance/payout/se; duration=272ms |
| Payout schedule search | POST | /admin/finance/payout/schedule/search | FAIL | 404 | HTTP 404, body preview: <!DOCTYPE html> <html lang="en"> <head> <meta charset="utf-8"> <title>Error</title> </head> <body> <pre>Cannot POST /admin/finance/payout/sc; duration=273ms |
| Invoice search | POST | /admin/finance/invoice/search | FAIL | 404 | HTTP 404, body preview: <!DOCTYPE html> <html lang="en"> <head> <meta charset="utf-8"> <title>Error</title> </head> <body> <pre>Cannot POST /admin/finance/invoice/s; duration=293ms |
| Reconciliation search | POST | /admin/finance/reconciliation/search | FAIL | 404 | HTTP 404, body preview: <!DOCTYPE html> <html lang="en"> <head> <meta charset="utf-8"> <title>Error</title> </head> <body> <pre>Cannot POST /admin/finance/reconcili; duration=269ms |
| Finance dashboard | GET | /admin/finance/dashboard | FAIL | 404 | HTTP 404, body preview: <!DOCTYPE html> <html lang="en"> <head> <meta charset="utf-8"> <title>Error</title> </head> <body> <pre>Cannot GET /admin/finance/dashboard<; duration=288ms |
| Revenue report | POST | /admin/finance/reports/revenue | FAIL | 404 | HTTP 404, body preview: <!DOCTYPE html> <html lang="en"> <head> <meta charset="utf-8"> <title>Error</title> </head> <body> <pre>Cannot POST /admin/finance/reports/r; duration=263ms |
| Commission report | POST | /admin/finance/reports/commission | FAIL | 404 | HTTP 404, body preview: <!DOCTYPE html> <html lang="en"> <head> <meta charset="utf-8"> <title>Error</title> </head> <body> <pre>Cannot POST /admin/finance/reports/c; duration=272ms |
| Tax report | POST | /admin/finance/reports/tax | FAIL | 404 | HTTP 404, body preview: <!DOCTYPE html> <html lang="en"> <head> <meta charset="utf-8"> <title>Error</title> </head> <body> <pre>Cannot POST /admin/finance/reports/t; duration=264ms |
| Cashflow report | POST | /admin/finance/reports/cashflow | FAIL | 404 | HTTP 404, body preview: <!DOCTYPE html> <html lang="en"> <head> <meta charset="utf-8"> <title>Error</title> </head> <body> <pre>Cannot POST /admin/finance/reports/c; duration=264ms |
| Host ledger by id | POST | /admin/finance/ledger/host/{hostId} | SKIP | - | Missing required test ID in environment variables |
| Guest ledger by id | POST | /admin/finance/ledger/user/{userId} | SKIP | - | Missing required test ID in environment variables |
| Ledger detail by id | GET | /admin/finance/ledger/{ledgerId} | SKIP | - | Missing required test ID in environment variables |
| Payout detail by id | GET | /admin/finance/payout/{payoutId} | SKIP | - | Missing required test ID in environment variables |
| Invoice detail by id | GET | /admin/finance/invoice/{invoiceId} | SKIP | - | Missing required test ID in environment variables |
| Invoice download | GET | /admin/finance/invoice/download/{invoiceId} | SKIP | - | Missing required test ID in environment variables |
| Reconciliation detail by id | GET | /admin/finance/reconciliation/{reconId} | SKIP | - | Missing required test ID in environment variables |
