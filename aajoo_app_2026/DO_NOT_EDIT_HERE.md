# Do not edit the app here

**This copy is a mirror. The app is developed in its own repository.**

```
https://github.com/nameeshPatiyal100/aajoo_app_latest
```

On this machine it is cloned at **`D:\Projects\aajoo_app_latest`**, and on the
Mac it is whatever `gh repo clone nameeshPatiyal100/aajoo_app_latest` produced.
**In that repo the app is at the ROOT** — `lib/`, `ios/`, `pubspec.yaml` — not
under an `aajoo_app_2026/` prefix.

## Why this file exists

The same source existing in two places is how a fix gets written twice and
shipped once. It has already happened on this repo: the Google Analytics tag
was added both to the frontend repo (where it deploys) and to the stale
`index.html` at this monorepo's root (where it does nothing).

Edit here and your change reaches no build, no store and no user. The Mac does
not clone this repo, and neither does CI.

## What this directory is still good for

Reading, history and the build artifacts already sitting in `build/`. It is
**not** stale: on 10 November its tracked tree was compared file by file
against the app repo — 610 identical, 0 missing, and the only three
differences were stray carriage returns with identical content. Nothing here
is unique.

Keeping it costs nothing and loses nothing. Editing it costs a day.

## If you need to bring a change from here into the app repo

Do **not** `git subtree split`. The app repo's history came from one split with
every `.apk`/`.aab` stripped, so the hashes no longer correspond and a fresh
split would rewrite the client's history and put 493 MB of artifacts back into
a 22 MB repo.

Mirror the tracked tree onto their tip instead, drop the five tracked APKs,
preserve each file's existing line endings, stage only what you changed, and
run `flutter test` green in a fresh clone before pushing. The full method is in
the `client-repo-sync` note and in `SESSION_HANDOFF_2026-11-10.md`.
