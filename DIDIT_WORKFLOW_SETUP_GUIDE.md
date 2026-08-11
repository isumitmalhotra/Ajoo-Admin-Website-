# DIDIT — Step-by-Step Workflow Setup (Host + Renter)

> **Goal:** create the two verification workflows our backend already expects, grab 4 values, paste them into Render. After this, host face/ID verification and guest (renter) booking KYC both go live.
>
> **Good news:** the code is **already built** — backend has the session-create call, the `/webhooks/didit` receiver, and admin **Approve/Reject** endpoints. You only need to do the console setup below; **no coding on your side.**
>
> **Console:** https://business.didit.me (the Aajoo account is already provisioned).

---

## Why two workflows?
- **Host workflow** (`host-kyc-v1`) → runs when a host submits a property (face + ID). Property stays **Pending** until Approved + admin sign-off.
- **Renter/Guest workflow** (`guest-kyc-v1`) → runs at **Confirm Booking** (the existing "Verify identity" button). Booking won't confirm until Approved. Re-verification is skipped if the guest verified in the last 90 days.

Both should contain the **same checks**; we just keep them as two separate workflows so host vs guest are tracked/reported separately and can diverge later.

---

## STEP 1 — Create the HOST workflow
1. Log in at **https://business.didit.me** → open the Aajoo project.
2. Left menu → **Workflows** (or "Verification Flows") → **+ Create Workflow**.
3. **Name it exactly:** `host-kyc-v1` (lowercase, no spaces).
4. Add these verification steps (toggle them ON, in this order):
   - ✅ **ID / Document Verification** (Aadhaar / PAN / Passport / Driving Licence — enable Indian documents)
   - ✅ **Liveness** → choose **Passive liveness**
   - ✅ **Face Match** (selfie ↔ document photo)
   - ✅ **IP / Location Analysis** (fraud signal) — optional but recommended
5. (Optional) Branding: set the logo/colors so the verification screen looks like Aajoo.
6. Click **Save**, then **Publish** (the workflow must be **Published**, not Draft).
7. Open the published workflow and **copy its Workflow ID** (a UUID like `wf_xxxxxxxx` or a long UUID). Keep it — this is **`DIDIT_HOST_WORKFLOW_ID`**.

## STEP 2 — Create the RENTER/GUEST workflow
1. **+ Create Workflow** again → name it exactly `guest-kyc-v1`.
2. Add the **same** steps as Step 1 (ID Verification + Passive Liveness + Face Match + IP Analysis).
3. **Save → Publish.**
4. Copy its **Workflow ID** → this is **`DIDIT_GUEST_WORKFLOW_ID`**.

## STEP 3 — Get the API key + webhook secret
1. Left menu → **API & Webhooks** (or **Developers / API Keys**).
2. **Copy the API Key** → this is **`DIDIT_API_KEY`**.
3. Find **Webhook Secret** (a signing secret). Copy it → **`DIDIT_WEBHOOK_SECRET`**. (If there's a "generate" button, generate it and copy.)
4. **Add a Webhook endpoint** with this exact URL:
   ```
   https://aajaodev.onrender.com/webhooks/didit
   ```
   - Method: **POST**
   - Subscribe to the **verification/session decision** events (Approved, Declined, In Review, etc.).
   - Save.

## STEP 4 — Put the values in Render (backend env)
1. Go to the **Render dashboard** → the **aajaoBackend** service → **Environment**.
2. Add / set these variables (names must be **exact**):
   ```
   DIDIT_API_KEY            = <from Step 3>
   DIDIT_WEBHOOK_SECRET     = <from Step 3>
   DIDIT_HOST_WORKFLOW_ID   = <from Step 1>
   DIDIT_GUEST_WORKFLOW_ID  = <from Step 2>
   DIDIT_BASE_URL           = https://verification.didit.me
   APP_VERIFY_RETURN_URL    = https://aajoohomes.com/verify/complete
   ```
3. **Save** → Render redeploys automatically (~2–3 min).

## STEP 5 — Confirm it's live
- Once the 4 values are set, the backend flips `kyc.config.isConfigured = true` and starts creating real DIDIT sessions.
- **Renter test:** log in as a renter → book a property → at checkout, the **Verify identity** button now opens the real DIDIT flow → finish it → the booking unlocks **after** DIDIT's webhook returns "Approved" (you'll briefly see an "under review" state — that's expected; approval is async via webhook, never on the on-screen "finished" callback).
- **Host test:** (after the new host wizard ships) the host's KYC step opens the host workflow; property shows **Pending** until Approved + an admin approves it in **Admin → Host → KYC queue**.

---

## What I'll do on the code side (no action needed from you)
- Wire the **host wizard's KYC step** to the host workflow (the guest one is already wired at checkout).
- Make host listings submit as **Pending** and surface them in the admin **Property Verification / KYC** queue with Approve/Reject (endpoints already exist: `/admin/host/kyc/approve`, `/admin/host/kyc/reject`).
- Add the 8 UI states (not verified / in progress / submitted / approved / declined+retry / in review / already-verified / expired).

## Notes / gotchas (already handled in code, FYI)
- Approval comes **only via the webhook** (`/webhooks/didit`), which verifies the `x-signature-v2` HMAC against `DIDIT_WEBHOOK_SECRET` — that's why the secret must match exactly.
- Verifications are valid **90 days** (guests aren't re-asked within that window).
- Free tier = **500 verifications/month** — fine for launch.

**If a DIDIT screen looks different from the labels above** (they update their console UI), send me a screenshot and I'll map the exact buttons — the four values we need are always: API key, webhook secret, and the two published workflow IDs.
