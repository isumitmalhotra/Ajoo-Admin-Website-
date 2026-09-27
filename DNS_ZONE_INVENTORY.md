# Vercel: everything connected, and the whole DNS zone

**27 September 2026.** Read directly from the Vercel dashboard, not guessed.

An earlier draft of this file was built from `dig` alone and said the zone had
eleven records. **It has seventeen.** A public lookup cannot enumerate a zone —
it can only confirm names you already know — so it missed a second pair of DKIM
records, the CAA set, and the two records that actually serve the website. That
gap is the whole reason to read the dashboard before planning a move.

---

## The account

| | |
|---|---|
| Team | `nameeshpatiyal100's projects` — **Hobby** |
| Storage (KV / Blob / Postgres) | **none** |
| Integrations | **one** — Entri Connect (a domain-setup service, added 9 Aug). It holds DNS write access. |
| Team-level shared env vars | none — the page 404s on Hobby |

**Usage over the last 30 days** — nothing is near a limit, so nothing is being
forced off Hobby by capacity:

| Meter | Used | Hobby limit |
|---|---|---|
| Fluid Active CPU | 34m 42s | 4h |
| Function Invocations | 10K | 1M |
| Edge Requests | 38K | 1M |
| Fast Data Transfer | 2.57 GB | 100 GB |
| Deployment Storage | 403 MB | 10 GB |

The reason to leave Hobby was never the meters — it is that **Hobby is not
licensed for commercial use**.

---

## The two projects

**`aajao-admin-web-s-iite-epy6`** — the live one.

* Domains: `www.aajoohomes.com` (production), `aajoohomes.com` (**307** →
  `www`), `aajao-admin-web-s-iite-epy6.vercel.app`
* Git: `nameeshPatiyal100/Aajao-Admin-WebSIite`, connected 23 August 2025
* Framework preset **Vite**, every build setting left at its default — no
  overrides at all. So the Render port needs exactly `npm ci && npm run build`
  producing `dist`.
* Deployment Protection: Vercel Authentication **on**, Standard Protection —
  previews require a login, production is public. Password Protection is a Pro
  feature and is off.
* SSL: two managed certificates, `aajoohomes.com` and `*.aajoohomes.com`,
  auto-renewing 28/29 November 2026.

**`aajao-frontend-vercel`** — dead. **No git repository connected**, **no
environment variables**, no custom domain, last touched 17 August. It serves a
stale build at `aajao-frontend-vercel.vercel.app` and nothing else. Safe to
delete, and worth deleting: a `.vercel.app` URL quietly serving an old build is
the kind of thing somebody eventually bookmarks.

---

## The environment variables — there are two

On the live project. Both **Production only**:

| Name | Scope | Last touched |
|---|---|---|
| `VITE_API_BASE_URL` | Production | added 24 Sep — the Singapore cutover |
| `VITE_GOOGLE_MAPS_KEY` | Production | 1 Sep |

Verified independently rather than taken on trust: the live bundle
(`/assets/index-B95p0lvC.js`, 3.18 MB) contains `https://api.aajoohomes.com`
and **no `onrender.com` host at all**. The cutover is genuinely complete and
nothing stale is baked in.

**Two things follow from this list.**

1. **Neither variable exists for Preview or Development.** Every preview
   deployment — every pull request — builds with no API base and no Maps key,
   and Vite bakes that absence in permanently. A preview is therefore not a
   valid test of the real site, which is easy to forget when reaching for one
   to check a fix.
2. **Two variables is the entire configuration.** That is real good news for
   the Render move: there is no hidden Vercel-side config waiting to be
   discovered halfway through. The port carries two values.

---

## The DNS zone — all seventeen records

Vercel hosts the zone (`ns1`/`ns2.vercel-dns.com`). The **registrar is a third
party** — GoDaddy, on the evidence of the mail records — and Vercel states it
plainly: *"Nameserver changes must be made with your domain's registrar."*

### The website — 2 records, and these are the trap

| Name | Type | Value |
|---|---|---|
| `@` | ALIAS | `090cbd1b3019aef3.vercel-dns-017.com` |
| `*` | ALIAS | `cname.vercel-dns-017.com.` |

Both carry a label from Vercel: **"Vercel automatically manages this record. It
may change without notice."**

This is the single biggest hazard in moving the zone. `ALIAS` is not a standard
record type, that hostname is specific to this project, and Vercel reserves the
right to change it. Copy it by hand into Cloudflare and the site works — until
Vercel rotates it, at which point the site dies for a reason nobody will think
to look for. **The zone must not move while Vercel is still serving the
website.** Once the site is on Render, these two records are replaced by
Render's own target anyway, which is precisely what makes Phase 4 the right
moment.

Note the `*` wildcard too: **every** unconfigured subdomain currently resolves
to the Vercel project instead of returning NXDOMAIN.

### The API — 1 record

| Name | Type | Value | TTL |
|---|---|---|---|
| `api` | CNAME | `aajoo-api-singapore.onrender.com.` | 60 |

Ours, added 24 September, with a comment on it saying so.

### Mail — 10 records, and this is why the zone is not free to move

| Name | Type | Value |
|---|---|---|
| `@` | MX 0 | `smtp.secureserver.net.` |
| `@` | MX 10 | `mailstore1.secureserver.net.` |
| `@` | TXT | `v=spf1 include:secureserver.net -all` |
| `_dmarc` | TXT | `v=DMARC1; p=reject; rua=mailto:dmarc_rua@onsecureserver.net; adkim=r; aspf=r;` |
| `@` | TXT | `brevo-code:f90d1f3a…` — Brevo domain proof |
| `brevo1._domainkey` | CNAME | `b1.aajoohomes-com.dkim.brevo.com.` |
| `brevo2._domainkey` | CNAME | `b2.aajoohomes-com.dkim.brevo.com.` |
| `secureserver1._domainkey` | CNAME | `s1.dkim.aajoohomes_com.5da.onsecureserver.net.` |
| `secureserver2._domainkey` | CNAME | `s2.dkim.aajoohomes_com.5da.onsecureserver.net.` |
| `email` | CNAME | `email.secureserver.net.` |

**Four DKIM records, in two pairs** — Brevo signs what the platform sends,
GoDaddy signs what a person sends from a mailbox. A `dig` of the apex shows
neither pair; they are findable only if you already know the selector names.
That is exactly how a hand-copied zone loses mail signing and nobody notices
until a week of rejections has gone by.

### Certificates — 3 CAA records

| Name | Type | Value | Lets who issue |
|---|---|---|---|
| `@` | CAA | `0 issue "pki.goog"` | Google Trust Services — Vercel |
| `@` | CAA | `0 issue "sectigo.com"` | Sectigo — GoDaddy |
| `@` | CAA | `0 issue "letsencrypt.org"` | **Let's Encrypt — Render** |

Worth checking before the frontend move, and now checked: **Render issues
through Let's Encrypt, and `letsencrypt.org` is already permitted**, so
`www.aajoohomes.com` will be able to get a certificate on Render. Had that line
been missing, the cutover would have failed at certificate issuance with an
error that reads like a Render fault and is actually a DNS one.

### Domain proof — 1 record

`@` TXT `D8935362` — GoDaddy's ownership token.

---

## Why mail matters even though no customer exists yet

The honest answer to "it is only us testing, what does email matter":

1. **Every OTP on this platform is an email.** SMS is dormant — it needs a
   provider and a DLT template we do not have. Signup, sign-in OTP, password
   reset, phone change and email verification all go out through Brevo, signed
   by those two `brevo*._domainkey` records. Break them and **nobody can get
   into the app** — not the client, not the tester, not us. It would also look
   exactly like an app bug, and the day would be spent looking for it there.
2. **`contactus@aajoohomes.com` is now published to Apple and Google** as the
   account-deletion contact on `/delete-account`, which both stores read as a
   compliance URL. Mail bouncing there is a store problem, not an inconvenience.
3. **DMARC is `p=reject`.** Not `quarantine`, not `none`. If SPF and DKIM stop
   lining up, receiving servers **refuse** the message outright — it does not
   land in a spam folder where someone might still find it.

And the mailboxes are GoDaddy's, not Vercel's. The risk in a DNS move was never
that Vercel holds the mail hostage. It is that ten mail records get recreated
by hand and one of them lands wrong.

---

## If the zone moves anyway — the order that makes it safe

Render has no DNS product, so the destination is **Cloudflare** (free, full
record control, a real API) or **GoDaddy's own DNS** (one account fewer, and
the mail records are already theirs).

**One safeguard is already in place:** every record sits at **TTL 60** except
the two Brevo DKIM CNAMEs at 300. The usual "drop the TTLs a day ahead" step is
therefore nearly free here — a mistake reverts in a minute rather than four
hours. Worth not throwing away by raising TTLs beforehand.

1. **Move the website to Render first, and watch it for 48 hours.** Not
   optional. Those two apex/wildcard ALIAS records cannot be copied to another
   host safely while Vercel is still serving the site.
2. **Export the zone.** Vercel offers *Upload Zone File*; use its export if one
   exists, otherwise build the file from the seventeen rows above. Cloudflare
   imports a zone file, which is far safer than retyping.
3. **Recreate and check row by row against this document.** Cloudflare's
   auto-import is a starting point, not an answer — it routinely misses TXT
   records and does not always carry MX priorities across.
4. **Set the apex, `www`, `api` and all four `_domainkey` CNAMEs to DNS-only
   (grey cloud).** Cloudflare proxies A and CNAME records *by default*. A
   proxied DKIM CNAME does not resolve to the signer and silently kills mail
   signing; a proxied `api` puts Cloudflare in front of Render's certificate.
5. **Carry the CAA records over.** Drop them and certificate renewal fails
   later, long after anyone would connect it to this change.
6. **Change the nameservers at the registrar.** This is the cutover, and the
   one step that cannot be rehearsed.
7. **Verify from a resolver that is not the new host's own** — `dig @8.8.8.8`
   and `@1.1.1.1` for all seventeen rows, including every `_domainkey` selector
   by name.
8. **Send a real mail and read its headers.** Trigger an OTP from the app and
   confirm `spf=pass`, `dkim=pass`, `dmarc=pass`. Then send *to*
   `contactus@aajoohomes.com` and confirm it arrives. Header checks, not "the
   email showed up" — under `p=reject`, only one of the two aligning is not
   enough.
9. **Leave Vercel's zone intact for a week.** Rollback is changing the
   nameservers back, and that only works while the old zone still holds the
   records.

---

## Recommendation

**Not this week, and never in the same change as the website.**

Moving the zone consolidates nothing, because Render cannot host DNS — it swaps
Vercel for Cloudflare. The one thing it genuinely buys is closing the Vercel
account, and that is Phase 4 of `FRONTEND_MOVE_TO_RENDER_TASKLIST.md`.

The ordering argument is the stronger one. Phase 3 changes the record that
serves the website. If the zone moves in the same window and mail stops, there
are two suspects and no way to separate them without undoing both — and one of
those suspects is a record Vercel has warned may change on its own.

**Do now, independent of all of the above:** add `VITE_API_BASE_URL` and
`VITE_GOOGLE_MAPS_KEY` to Preview, and delete the dead `aajao-frontend-vercel`
project.
