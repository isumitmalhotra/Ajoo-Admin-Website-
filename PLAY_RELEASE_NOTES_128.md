# Play release — build 128 (versionName 1.0.0)

**Artifact:** `aajoo_app_2026/build/app/outputs/bundle/release/app-release.aab`
**Size:** 88.3 MB · **versionCode 128** (read from the bundle's protobuf
manifest, not from pubspec — an AAB's manifest is protobuf, so `aapt2` refuses
it and the APK metadata beside it belongs to a stale build)

Previous production build: **127**.

---

## What's in it

### A guest can book one room instead of the whole property

The headline. Until now a host could list their property room by room on the
app — that shipped with the wizard — and a guest on the app could not buy one
of those rooms. The web could. This closes that.

* A room table on the property page: each room with its own price for the
  chosen dates, how many are left, beds, and photographs.
* **"Only 1 left"** rather than a yes/no, because that is what makes a guest
  decide.
* A sold-out room keeps its price, so a guest can see what they missed.
* The whole property is still bookable underneath, at the host's own separate
  buyout price — never the sum of the rooms.

### A guest can negotiate one room

The offer sheet now asks which room the offer is for. Each room type has its
own floor and ideal, so an offer names what it is for rather than being judged
against the whole building's price.

### Smaller

* Search cards for a guesthouse now lead with the cheapest room — "from
  ₹1,200" — rather than the buyout price for the entire building, which made
  them read several times dearer than anything a guest could actually book.

---

## Store listing text

> You can now book a single room at properties that rent room by room — see
> what each room costs for your dates, how many are left, and book just the
> ones you need. You can also make an offer on a specific room rather than the
> whole property. Guesthouses in search now show their cheapest room price.

---

## Before you publish

1. **Managed publishing.** Leave it ON. With it off an approval goes live
   irrevocably; with it on you choose the moment.
2. **Check the release name is not blank** on the Play review screen. A blank
   name means the AAB never actually attached — it has happened here before.
3. The backend this build needs is **already live** (phase 2 and phase 3 both
   deployed 2026-11-02), so there is no ordering constraint: the app can go
   out whenever you are ready.
