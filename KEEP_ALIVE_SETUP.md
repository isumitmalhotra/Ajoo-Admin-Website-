# Keep-Alive Setup — Render Free-Tier Cold-Start Mitigation

The backend runs on Render's free tier, which puts the service to sleep
after ~15 minutes of inactivity. The first request after a sleep takes
~30–50s to wake the container, which feels broken to users on login/home.

**Status: solved as of 2026-08-11 — see Option D below, which is live.** The
options after it are alternatives that each need a third-party account; they are
kept for reference in case the GitHub Action is ever removed.

> **Permanent fix:** upgrade Render to a paid tier ($7/mo "Starter" plan
> has no sleep). Use that once you have paying users. Until then, the
> keep-alive ping covers it for $0.

---

## Endpoint to ping

```
GET https://aajaodev.onrender.com/health
```

Returns 200 with `{"status":"ok","service":"aajao-backend","uptime":<s>,"timestamp":"..."}`.

- No rate limiter on this route — safe to ping every 5 min.
- No DB call — won't go red when the DB blips.
- Both `GET` and `HEAD` work.

---

## ✅ Option D — GitHub Actions (**this is the one that is live**)

Set up 2026-08-11. Nothing to do; it is already running.

[`.github/workflows/keep-alive.yml`](.github/workflows/keep-alive.yml) in **this**
repo pings `/health` every 10 minutes, five times per run at 100-second
intervals. Verified on the first run: 5/5 answered, and backend uptime went from
797s (it had just slept and woken) to over 1,800s and climbing.

**Why it lives in this repo and not the backend repo.** The ping only has to
reach a public URL — it does not need to sit next to the backend code. The
backend and frontend repos are **private**, where Actions is capped at 2,000
minutes/month; a job every 10 minutes bills 4,320 and runs past the free tier.
This repo is **public**, where Actions minutes are unlimited, so it costs nothing.

**Why five pings per run instead of one.** GitHub's scheduler is best-effort and
runs late under load. A single ping per run leaves a gap whenever the next
schedule slips, and a gap past 15 minutes puts the service straight back to
sleep. The overlapping coverage absorbs the delay.

**Checking it.** Actions tab → *Keep backend awake*. Each run prints the pings
and writes the backend's uptime to the run summary. **Uptime climbing past ~900s
and staying there is the proof it works** — if it keeps resetting to a low
number, the service is still sleeping between pings.

**Two things that would stop it:**

1. GitHub **disables scheduled workflows after 60 days with no commits** to the
   repo. Active development keeps it alive; a long quiet spell does not. Any
   commit re-arms it, or trigger it by hand from the Actions tab.
2. Making this repo **private** would put the job back inside the 2,000-minute
   cap and it would stop part-way through each month.

**This is still a workaround.** The real fix is Render's $7/mo Starter tier,
which does not sleep at all — worth doing before real users, and definitely
before payouts go live.

---

## Option A — cron-job.org (free, needs an account)

1. Go to https://cron-job.org and create a free account.
2. Click **Create cronjob**.
3. Fill in:
   - **Title:** `AajaoHomes keep-alive`
   - **URL:** `https://aajaodev.onrender.com/health`
   - **Schedule:** "Every 10 minutes" (24×7).
   - **Notifications:** enable email-on-failure.
4. Save.

Free plan gives 50 cronjobs and 1-minute resolution — more than enough.

## Option B — UptimeRobot (free, needs an account)

1. Sign up at https://uptimerobot.com (free tier: 50 monitors, 5-min interval).
2. **Add New Monitor**:
   - Monitor type: **HTTP(s)**
   - Friendly name: `AajaoHomes /health`
   - URL: `https://aajaodev.onrender.com/health`
   - Monitoring interval: **5 minutes** (free-tier minimum)
3. Save.

UptimeRobot also gives you a public status page for free if you want one.

## Option C — BetterStack (free, needs an account)

Same idea as UptimeRobot, nicer dashboard. https://betterstack.com

---

## Why not self-ping from inside the backend?

A `setInterval(..., '/health')` inside the Node process **does not help**
— Render puts the entire process to sleep, so the interval also stops.
The pinger has to be external.

---

## Verifying it works

After setting up the monitor, give it ~30 min and then check Render logs.
You should see a steady drip of:

```
HTTP Request { method: 'GET', path: '/health', statusCode: 200, ... }
```

every 5–10 min, and the service should respond instantly when you open
the app from cold.

If you stop seeing these in Render logs but they're firing in the
monitor's history, check Render's "Suspended" status — free tier also
suspends after 750 hours/month of active runtime if you exceed the cap.

---

## When to remove this

When you upgrade Render to a paid tier (Starter or higher), the sleep
behavior goes away and the keep-alive monitor becomes redundant. Leave
the monitor in place anyway — it doubles as an uptime alarm.
