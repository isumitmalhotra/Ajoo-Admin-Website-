# Play release — build 129 (versionName 1.0.0)

**Artifact:** `D:\Projects\aajoo_app_latest\build\app\outputs\bundle\release\app-release.aab`
**Size:** 88.3 MB · **versionCode 129**
**sha256** `6fdb0b3c8731294dc61b0458c36cacbfafde969af3a4b2bf6623a8c2c12d7f0a`

Previous production build: **127**, and it is live. Play Console reads
"Active · Latest release: 127 (1.0.0) · 1 country/region · 118 installs"
(checked 11 November). An earlier draft of this file said 121; that was wrong
— 127 did reach Play. **128 was never uploaded to Play**: it is the iOS build
now in App Review.

**Why Android is 129 while iOS is 128.** They are not the same code this time.
128 carries the iOS credential fix and went to App Review on 10 November. The
Android fix landed after it, so it gets its own number — one build number, one
artifact. The next iOS build will be 129 or later and will carry both.

---

## What's in it

### Sign in with Apple works on Android — it never has before

The headline, and it is a repair rather than a feature. The button has been on
the Android login screen since September and has never completed a sign-in in
any build.

Two independent faults, so fixing either alone would have changed nothing:

* The redirect URL pointed at Firebase's own auth handler, which finishes a
  Firebase **web** sign-in inside its own page and never hands control back to
  an app. The browser tab simply sat on Apple's page.
* `AndroidManifest.xml` had no `SignInWithAppleCallback` activity, so even a
  correct redirect had nowhere to land.

There is now a server route (`/auth/apple/android`) whose only job is to turn
Apple's form post into the Android intent the package expects, and the activity
that receives it.

**Why it matters more than one button:** an account created on an iPhone with
Sign in with Apple has an **unusable password by design**. Until this build,
anyone who signed up that way could not reach their own account on an Android
handset by any route at all.

### Also in 127–129, none of which reached Play

* A guest can book and negotiate a **single room** at properties that rent room
  by room — each room with its own price for the chosen dates, how many are
  left, beds and photographs. The whole property is still bookable at the
  host's own separate buyout price.
* Search cards for a guesthouse lead with the cheapest room — "from ₹1,200" —
  rather than the buyout price for the whole building.
* The location purpose string Apple's scan asked for (ITMS-90683).

---

## Store listing text

> Sign in with Apple now works on Android. You can also book a single room at
> properties that rent room by room — see what each room costs for your dates,
> how many are left, and book just the ones you need, or make an offer on a
> specific room. Guesthouses in search now show their cheapest room price.

---

## Before you publish

1. **Test Sign in with Apple on a real Android phone first.** Sideload
   `aajoo-homes-1.0.0-build129-release.apk` (sha256
   `c7be331ff5fd05557a927e1369d4595fdda91c87333f547cba853a6fe5a1c67c`). The
   fix cannot be proven by any test — it needs Apple, a browser and a device.
   If Apple shows **invalid_client** or **redirect_uri mismatch**, the Return
   URL is not registered against the Services ID and the build must not ship.
2. **Managed publishing stays ON.** With it off an approval goes live
   irrevocably.
3. **Check the release name is not blank** on the review screen. A blank name
   means the AAB never attached — it has happened on this app before.
4. An existing **draft** release greys out "Create new release". Discard it
   first.
5. The store page's "Updated on" date **lags** the live release. It is not
   proof of anything.
6. **The APK carries the live payment key.** Completing a checkout in it
   charges a real card. Everything up to the payment sheet is safe.

## Verified before release

* Endpoint `api.aajoohomes.com`, key `rzp_live_TjqzCwo7CT9g4E`, version
  `1.0.0+129` — all read back out of the built binary, not assumed.
* The old Firebase redirect is **absent** from the artifact.
* `SignInWithAppleCallback` and the `signinwithapple` scheme are present in the
  bundle's manifest.
* 783 app tests passing, 1 skipped. Backend 241/241.
