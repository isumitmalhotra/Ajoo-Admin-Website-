# Render and PlanetScale — what has been bought, what it does, and the decisions we need

## 1. The short version

Two purchases were made this week, and both were the right ones. Neither is finished yet, because each has a second half that costs money and depends on a decision only the company can take:

1. **Render** — the workspace is now on the **Pro plan ($25/month)**. That buys the team workspace. It does **not** upgrade the server: the API still runs on Render's **Free** compute plan, in **Oregon (USA)**, and still goes to sleep when idle. A production server is a separate charge — **$25/month** — and it has to be a **new** server in **Singapore**, because Render cannot move an existing one.
2. **PlanetScale** — the account exists and a database was created. It was created in **Mumbai**; we advised deleting it and creating it again in **Singapore**, next to the server, and that is where it stopped, because PlanetScale's price today is **$47/month** in Singapore (**$39** in Mumbai), not the $25 our 18 September document quoted. We did not want to commit to a different number without telling you.

**We are asking for three answers (section 7).** Once we have them, the production stack is built within two working days, and nothing changes for anyone using the current test system until you say so.

## 2. What has been paid so far — and for what

| Purchase | What it is | What it has cost | What it has changed |
|---|---|---|---|
| **Render Pro workspace** | The team account on Render: unlimited members, 25 GB bandwidth, 15 custom domains, 1,000 build minutes, audit logs, autoscaling *option*. A flat fee "plus compute costs", in Render's words. | **$25/month**, pro-rated — the September invoice will show about **$10** because it started mid-month. The card on file (Visa ending 4263) is accepted, so the card problem that blocked AWS is behind us. | Nothing yet for users. The API server (`aajaodev`) is still the Free plan in Oregon. September's server charge is **$0**; 374 of the 750 free hours are used. |
| **PlanetScale organisation** | The database company's account (`aajoolive`) with a card. | A **PS-10** database was created in Mumbai on 18 September and, on our advice, **deleted on 19 September** so it can be recreated in the right region. The first invoice will carry **one day of usage, roughly $1–2**. Nothing else has been charged. | Nothing yet. The live test database is still on Clever Cloud (Paris). |

Both accounts are correctly in the company's name (AAJOO HOMES PRIVATE LIMITED, with the GST number on the Render billing profile).

## 3. What we are asking for now — the second half of each

| Item | Monthly cost | Why it is needed |
|---|---|---|
| **Render compute plan `1c-2g`** (1 CPU, 2 GB) for a **new** API server in Singapore | **$25** | The Free plan sleeps after idle — every first visit waits 30–50 seconds for the server to wake — and cannot have a health check, a maintenance page or more than one instance. Oregon is 470 ms from India; Singapore is about 80 ms. Render offers Oregon, Ohio, Virginia, Frankfurt and Singapore — **no India region** — and does not let a server change region, so this is a new server, not an upgrade of the old one. |
| **PlanetScale PS-10** in Singapore | **$47** (Mumbai: **$39**) | The production database, three nodes across three zones, daily backups, 10 GB storage. The 18 September document said $25: that was the price shown on PlanetScale's pricing page that day; the console today shows the two region prices above. We apologise for the difference and will verify prices in the console before quoting again. |
| Together with the Pro workspace already bought | **$97/month** (Singapore) or **$89/month** (Mumbai) | For comparison, the platform's hosting today costs **$0/month** and behaves accordingly. Vercel (the website) and everything else are unchanged. |

## 4. Mumbai or Singapore — what it means on the site

Nobody uses the database directly; only the API server does. Each screen the API serves asks the database several questions one after the other — typically five to fifteen, and the heavy ones (saving a listing, checkout, a payout run, the finance dashboard) twenty to forty.

- Server in Singapore, database in Singapore: each question takes 1–2 ms. A screen spends 15–30 ms in the database.
- Server in Singapore, database in Mumbai: each question crosses the sea, 40–60 ms. The same screen spends **300–700 ms** in the database, on every tap; the heavy screens add **1–2 seconds**, and because two people saving at once hold each other up for that long, the same server serves fewer people.

Mumbai does not bring the data closer to any user (no user connects to it), and there is no legal requirement to keep this data in India — the payments rule applies to Razorpay, and the platform stores no card data. Mumbai would be the right choice only if the server itself moved to an Indian cloud one day, and a 21 MB database moves in an afternoon. **Our recommendation: Singapore, for $8 more a month.**

## 5. What we found in the Render account (read-only)

- The service is deployed from the correct repository and branch, and the code that is live is today's latest — the deployment pipeline is healthy.
- It is on the **Free** compute plan, in **Oregon**, with **no health check**, **no custom domain**, and 34 configuration values in place (including the encryption key for bank details and the token that protects the health page). Two of those values are test-mode settings that will not exist on the production server.
- The Pro workspace on its own changes none of this. The visible slowness testers report today comes from the Free plan and the distance, not from the software.

## 6. What happens after your answers

1. **Database**: the fresh production database is created in the region you choose, with foreign keys enabled and the platform's structure and reference data (categories, amenities, cities, legal texts, CMS, admin accounts) loaded — **none of the four months of test data**, as agreed. Test accounts, listings and bookings stay on the old system until it is retired.
2. **Server**: a new Render service in Singapore on `1c-2g`, `api.aajoohomes.com` pointed at it, the same configuration copied across, the Razorpay and identity-check webhooks moved.
3. **Switch**: only when you say so — the website is pointed at the new server, testers reinstall the app (build 107, built against the permanent address), and the old Oregon server and the Paris database are retired 48 hours later.

Nothing in this plan touches the website's hosting (Vercel), the maps, the image storage, or the chatbot.

## 7. Decisions needed

1. **PlanetScale region and price:** Singapore at **$47/month** (recommended) — or Mumbai at **$39/month**?
2. **Render compute plan:** approve **$25/month** for the new Singapore server (`1c-2g`), on top of the Pro workspace already bought?
3. **Who presses the buttons:** with your go-ahead we create both in your logged-in consoles while you watch, as we did today; the database password is copied by you, never seen by us. Or the company creates them and we take it from there.

With those three answers, the production stack exists within two working days; the switch itself waits for your word.

---

*Prices as displayed in the Render and PlanetScale dashboards on 19 September 2026 (Render: Pro $25/month flat plus compute; compute `1c-2g` $25/month. PlanetScale: PS-10 $47/month in ap-southeast-1 Singapore, $39/month in ap-south-1 Mumbai). Latency figures are typical inter-region round trips, not a guarantee. Render's region list and its "no region change" rule are from Render's documentation on the same date.*
