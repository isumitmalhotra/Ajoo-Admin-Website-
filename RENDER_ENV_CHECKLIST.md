# Render environment — what to set, and how to know it worked

**Status as of 2026-08-10, measured on production via `GET /health/env`:**

```json
"ready": false,
"missingRequired": ["JWT_SECRET","CLOUDINARY_CLOUD_NAME","CLOUDINARY_API_KEY","CLOUDINARY_API_SECRET"],
"dbCutoverSafe": false,
"dbChecks": {"DB_USER":"DIFFERS","DB_PASSWORD":"DIFFERS","DB_NAME":"DIFFERS","DB_HOST":"DIFFERS","DB_PORT":"DIFFERS"}
```

The service only stays up because `config/db.config.js` still reads hardcoded
literals and ignores the environment entirely. **All five `DB_*` values in Render
are wrong.** Switching the code to `process.env` today would repeat the July
outage within seconds.

This is the one task I can't do for you — it needs the Render dashboard.

---

## Step 1 — Correct the five `DB_*` values

Render → the backend service → **Environment**. The correct values are the live
literals in `aajaoBackend-render/config/db.config.js`, lines **26–32**. Copy them
from there (or from the Clever Cloud dashboard, which is the real source of truth).

| Var | Where the right value is |
|---|---|
| `DB_USER` | `db.config.js:26` |
| `DB_PASSWORD` | `db.config.js:27` |
| `DB_NAME` | `db.config.js:28` |
| `DB_HOST` | `db.config.js:29` |
| `DB_PORT` | `db.config.js:30` — **this is not 3306.** The Clever Cloud instance uses a non-standard port; a wrong port here is the easiest way to repeat the outage |

**Check for the decommissioned host.** If any variable anywhere in the Render
environment contains `brcbbhhvhgihy7sgm6ca`, delete it. That host is dead
(`ENOTFOUND`) and is what broke production in July. The live one starts
`bf0mpow9qbd34cpwy8in`.

There is also a commented-out `bc6psmwfa4qmanbscjwn` block at `db.config.js:17–23`
— that is an older instance, not the current one. Don't copy from it.

## Step 2 — Add the four missing variables

| Var | Value |
|---|---|
| `JWT_SECRET` | Generate a fresh random string — **do not reuse** anything from git history. `openssl rand -base64 48` is fine. Setting this invalidates existing sessions; everyone signs in again, which is the correct outcome given the old secret was a committed fallback |
| `CLOUDINARY_CLOUD_NAME` | `db.config.js:4` |
| `CLOUDINARY_API_KEY` | `db.config.js:3` |
| `CLOUDINARY_API_SECRET` | `db.config.js:5` |

## Step 3 — Delete `OTP_DEV_BYPASS`

It is currently set to `true` on Render. This is the variable that made
`POST /user/verify-otp {userId, otp:"0000"}` return a valid JWT for **any**
account id — and ids are sequential, so that included hosts and staff.

The code now also requires a loopback origin, which is unreachable on Render, so
the hole is closed either way. But the variable should not be there. Remove it
rather than setting it to `false`.

## Step 4 — Confirm before touching any code

```bash
curl -s https://aajaodev.onrender.com/health/env
```

You need **both** of these in the response:

- `"ready": true`
- `"dbCutoverSafe": true`

`ready` alone is not enough — it only checks that variables are *present*. July's
outage was a variable that was present and wrong. `dbCutoverSafe` is the one that
compares each `DB_*` against the instance the service is actually connected to.

## Step 5 — Then, and only then, the cutover

Once the probe reads green, the code change is small: `db.config.js` goes back to
`process.env.*` with the fail-fast check. Tell me when step 4 is green and I'll
do it and verify login before and after.

---

## Still outstanding after all of the above

Every credential in `db.config.js` is in git history and should be rotated —
DB password, Razorpay secret, Cloudinary secret, Google OAuth secret, the Gmail
app password. Rotating them is a separate pass, and it has to happen *after* the
env cutover or you'll be chasing two moving targets at once.

The optional-but-unset list is also worth filling in while you're in there:
`MAIL_EMAIL`, `MAIL_PASSWORD`, `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`,
`GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `FRONTEND_URL`. They all currently
fall back to the hardcoded literals.
