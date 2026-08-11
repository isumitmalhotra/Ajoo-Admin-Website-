# AajooHomes — Production Go-Live Checklist (Phase 4 cutover)

> **Status:** execution-ready. **Do NOT run these for the test-mode v1** — the dev-bypasses
> below are what make test-mode signup/KYC/payments work without live infra. Run this
> checklist only at the real go-live, once the client provides credentials.
> **Repos:** FE `aajao-frontend-vercel` (push `main` → Vercel) · BE `aajaoBackend-render` (push `main` → Render).

---

## 0 · Pre-flight
- [ ] Take a DB backup (Clever Cloud MySQL) before any change.
- [ ] Confirm latest `main` is deployed on Vercel (FE) and Render (BE).

## 1 · Client credentials → Render env vars (#20–#23)
Set these in the Render dashboard (BE service), then **restart**:

| Item | Env vars | Verify |
|---|---|---|
| **Cloudinary (#20)** | `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` | Upload a property image / category icon → returns a Cloudinary URL |
| **Brevo email (#21)** | `BREVO_API_KEY`, `MAIL_FROM` (verified sender) + set `OTP_DEV_BYPASS=false` | Request an OTP → real email arrives < 30s |
| **Razorpay live (#22)** | `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` (live `rzp_live_*`) | Boot log shows no "env not set" fallback; one real ₹1 payment succeeds + invoice |
| **DIDIT KYC (#23)** | `DIDIT_API_KEY`, `DIDIT_WEBHOOK_SECRET`, `DIDIT_HOST_WORKFLOW_ID`, `DIDIT_GUEST_WORKFLOW_ID`, `APP_VERIFY_RETURN_URL` | Register webhook `https://<backend>/webhooks/didit`; host KYC flips to Approved |

> Also set FE env `VITE_RAZORPAY_KEY_ID` (live key) on Vercel if the checkout reads it client-side.

## 2 · Revert the 9 DEV-BYPASSES (#19)
All marked `// [DEV-BYPASS]` in code. **Backend (`aajaoBackend-render`):**
- [ ] `controllers/user.controller.js` ~L163 — restore mandatory `req.file` check in `createUser` (document required on signup).
- [ ] `controllers/user.controller.js` ~L211 — restore unconditional KYC doc record creation.
- [ ] `controllers/user.controller.js` ~L297 — remove the `if (reqData.otp === '000000') {…}` master-OTP block.
- [ ] `schema/user.schema.js` ~L56–77 — restore `doc_type` + `doc_number` as `.required()` in `createUser`.

**Mobile (`aajoo_app_2026`) — only when shipping the app:**
- [ ] `…/auth/basic_info/basic_info_screen.dart` ~L230 — restore `'Please upload a document'` validation.
- [ ] same file — remove `_skipStep3AndSave()` + the "Skip for now (dev)" button.
- [ ] `…/auth/auth_controller.dart` ~L208 — restore `idDoc: governmentIdImage.value!`.
- [ ] `…/auth/auth_controller.dart` ~L209 — restore `docType: int.parse(...)`.
- [ ] `…/controller/auth_controller.dart` ~L267 — restore bang/`int.parse`/docNumber.

> After backend reverts: push `aajaoBackend-render` `main` → Render redeploys.

## 3 · Config hardening (#24)
- [x] CORS + API base URL: deployed FE hits the correct backend via `VITE_API_BASE_URL` fallback (`configs/apis.ts`) and the live site already works — **OK for launch**.
- [ ] *(optional hygiene)* unify the customer axios hardcoded URL (`src/axios/axios.ts`) with `API_BASE_URL` so there's one source (INT-01).

## 4 · Post-cutover verification
- [ ] Real signup → real OTP email → login.
- [ ] Host KYC via DIDIT → Approved → property can go live.
- [ ] Real ₹1 Razorpay payment → booking confirmed + invoice generated.
- [ ] `financeSmoke.js` + `hmsSmoke.js` green against prod.

## 5 · Rollback
- Re-set `OTP_DEV_BYPASS=true` + restore bypass commits if a blocker appears; restore DB from the pre-flight backup.
