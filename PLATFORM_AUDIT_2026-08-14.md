# Platform audit — started 2026-08-14

End-to-end audit of the whole platform against `_Web App Bugs.xlsx`, plus a
sweep for dead APIs, unsynced data, dummy data and errors that should not be
there. Web and app.

**This file is the running record across all phases.** Anything found and not
yet fixed lives in §Open below, so nothing is carried only in conversation.

## The two sheets

| Sheet | Rows | What it is |
|---|---|---|
| `Aug 08-26` | 28 (8 headers + **20 items**) | web / admin — "Block W" |
| `Aug 08-26  App` | 105 | mobile — "Block A", = A-1…A-83 |

The Status column in the workbook says "Pending" against every web row. That
column was last touched on 10 Aug, **before** most of the fixes landed — it is
the client's own tracking, not evidence. Everything below was checked against
the running system instead.

## Phases

| Phase | Scope | Status |
|---|---|---|
| 1 | Admin portal — the 20 web-sheet items | ✅ **Done** — 19/20, W-13 partial |
| 2 | Guest web E2E — every public page, dead APIs, dummy data | ▶ In progress |
| 3 | Host web E2E | Queued |
| 4 | App E2E | Largely covered 2026-08-13 |
| 5 | Fix → redeploy → re-verify | Rolling |

## Deployed and verified live

| What | Commit | Verified in production |
|---|---|---|
| CORS PUT/PATCH | BE `1e8aa98` | `OPTIONS` from `https://www.aajoohomes.com` → `204`, `access-control-allow-methods: GET,POST,PUT,PATCH,DELETE,OPTIONS` |
| Offer note reaches admin | BE `dfe7f92` | deployed |
| User Active/Inactive toggle | FE `ffdcb7c` | string `Deactivate this user` present in the live bundle |
| Add User / Add Host dialog | FE `c75dfcb` | `Add New Host`, `A profile photo is required` present |
| Offer note rendered | FE `f67f5ca` | `Message sent with the offer` present |

---

## Phase 1 results — the 20 web items

### 🔴 Root cause behind several: PUT and PATCH were CORS-blocked

`app.js` allowed `GET, POST, DELETE, OPTIONS` only. Every PUT/PATCH failed its
preflight and died inside the browser — status 0, empty body, nothing in the
server log. Nine endpoints were dead **on the web only**; the mobile app was
unaffected because Dio is not a browser and sends no preflight. That is why
"works in the app, not on the web" kept recurring.

```
PUT  /admin/finance/payout/:id/approve   ← "payout is not working"
PUT  /admin/finance/payout/:id/reject
PUT  /admin/finance/payout/schedule/:id
PUT  /admin/finance/reconciliation/:id/resolve
PUT  /admin/notifications/:id/read
PUT  /host/notifications/:id/read
PUT  /host/payout-account/update         ← hosts could not save bank details
PUT  /host/profile/update
PATCH /listing/media
```

Proof, same button before and after: `PUT …/approve` went from **status 0,
empty body** to **400** carrying the server's real message, which the admin
now sees on screen.

### Item by item

| # | Item | Status | Evidence |
|---|---|---|---|
| W-1 | Host name missing on payout detail | ✅ works | "To Ashish Rahi", Host ID #133, email |
| W-2 | Payout detail (host / booking / user / bank) | ✅ works | host + masked account + booking + guest + property + full ledger |
| W-3 | Period shows invalid data | ✅ correct | fixed in code; payouts 7–8 (post-fix) carry real periods. Payouts 1–6 predate it and have **no linked booking dates** — checked — so "—" is honest, nothing to backfill |
| W-4 | Payout is not working | 🔧 fixed | CORS. Now returns 400 naming `RAZORPAYX_KEY_ID/KEY_SECRET/ACCOUNT_NUMBER`. **Cannot send money until those 3 env vars are set** |
| W-5 | Invoice download not working | ✅ works | `200 application/pdf`, 1792 bytes |
| W-6 | Reports should show the period in the file | ✅ works | CSV opens `Aajoo Homes — Cash flow report / Period,2026-08-01 to 2026-08-14 / Generated,…` |
| W-7 | Active/Inactive button not working | 🔧 built | The control **did not exist** — the redesign made status a read-only badge. Wired to `/admin/user/update/status` (which already writes an audit row). Verified `200 Status Updated Successfully`; test host restored to Active |
| W-8 | Doc number validation by doc type | 🔧 built | Server always enforced it. Client now matches: Aadhaar 12 digits, DL `MH0123456789012`, Passport `A1234567`. Verified: Passport + 12-digit Aadhaar → "Passport must be like A1234567" |
| W-9 | Error message should match the error | 🔧 built | Empty submit names all ten fields individually, incl. "A profile photo is required" |
| W-10 | Where can I check the negotiation message | 🔧 fixed | The offer's note lives on the offer row; the thread read the chat table, so an offer with a note but no chat said "no messages were exchanged" **and the note was never sent to the admin at all**. Now included and rendered above the thread |
| W-11 | Rename form to "Add New Host" | 🔧 built | — |
| W-12 | Add host form is not working | 🔧 built | There was no form. `src/pages/admin/*` (15 folders) is unrouted dead code. One dialog now covers user and host — the backend has always had one endpoint, `/admin/user/create` with `user_isHost` |
| W-13 | Host **update** form title | ⚠️ **partial** | Creation built; there is still no host *update* form in the new admin. Same cause as W-11/12 |
| W-14 | Description points vanish after save | ✅ verified | Property 15 reads its saved point back; confirmed in `propDetail_extra` |
| W-15 | Same for property document upload | ✅ fixed | Docs live in **two** tables (admin → `tbl_attachments`, wizard → `tbl_property_documents`); the read merges both |
| W-16 | Pet / Smoking unchanged after save | ✅ verified | DB `0/0` ↔ form loads `0/0` |
| W-17 | Deleted host still shown on property | ✅ fixed | Deleting a host now deactivates their listings — they used to stay searchable and bookable with no host behind them |
| W-18 | Logo missing on email | ✅ fixed | Templates pointed at placeholder `yourcompanylogo.com`; now `LOGO_URL`, asset verified `200 image/png`, 26,351 bytes |
| W-19 | Host full info not on profile | ✅ works | `/host/profile/get` returns fullName, email, phone, address, city, verification_status. Its **update** is a PUT — was CORS-blocked, now fixed |
| W-20 | Cannot log in as an unverified user | ✅ fixed | Unverified now routes to the code step instead of "No record found", and the password is checked **first** so the endpoint is not an account-existence oracle |

---

## Open — carry forward

### Blocked on the client (nothing more I can do)

| # | Item | What is needed |
|---|---|---|
| C-1 | 🔴 `OTP_DEV_BYPASS` is `true` in production | Set `false` in Render. OTP can be bypassed on a live system |
| C-2 | 🔴 Payouts cannot send money | `RAZORPAYX_KEY_ID`, `RAZORPAYX_KEY_SECRET`, `RAZORPAYX_ACCOUNT_NUMBER` (+ `FIELD_ENCRYPTION_KEY`) |
| C-3 | Render env wrong | 5 `DB_*` incorrect, 4 vars missing — `RENDER_ENV_CHECKLIST.md` |
| C-4 | Phone verification (A-5) | SMS provider credentials + DLT approval |
| C-5 | App loader / ringtone / launcher icon (A-1, A-2, A-3) | The branded assets |
| C-6 | List-your-property parity (A-77) | The SEO design + a decision to schedule the Listing Engine port |
| C-7 | Unbacked safety claims (E-13) | Per claim: build the feature or drop the line |

### Engineering — found, not yet fixed

| # | Item | Notes |
|---|---|---|
| P-1 | W-13 host **update** form | Creation exists; update does not |
| P-2 | Placeholder identities in finance | Invoices show `Host #111` / `Guest #123`, payouts `Host #12`. IDs where names belong |
| P-3 | Blank columns everywhere | User PHONE, host LOCATION, invoice PARTY all `—` on every row |
| P-4 | Property form Submit is silent on validation failure | Errors render beside fields only. On property 7 it did nothing because zip/country are NULL in the DB — no top-level "fix these" signal |
| P-5 | Legacy admin is dead code | All 15 folders of `src/pages/admin/*` unrouted. Delete or restore deliberately |
| P-6 | `apiValidation.ts` is documentation only | Not wired to anything, and says POST where the code uses PUT |
| P-7 | Junk city labels (E-3) | ~4,260 listings show wrong cities; needs a licensed geocoder |
| P-8 | Categories are a placeholder (E-15) | Even split across 9 categories; not real classification |
| P-9 | App: notifications reopen on cold start | Suspect `NotificationRoutingMiddleware` |
| P-10 | App: listing upload size | ~4MB never completed; ~180KB took ~90s. Needs client-side image compression |

---

## Phase 2 — guest web E2E

Findings recorded here as they are confirmed.
