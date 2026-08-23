# Testing checklists

The three interactive QA documents published as Claude artifacts. Sources live
here so a future session can update them instead of rebuilding from scratch —
they were previously only in a session scratchpad, which does not survive.

| Doc | Published at | Size |
|---|---|---|
| Host readiness | https://claude.ai/code/artifact/36484046-f358-47db-b9cf-f1457f1ce86d | 13 phases, 128 checks |
| Guest readiness | https://claude.ai/code/artifact/3923b696-df3b-4b67-b3be-4124f11827ab | 15 phases, 121 checks |
| Admin readiness | https://claude.ai/code/artifact/9e0ffc5f-76e2-450c-aa90-22d8c7819a7d | 14 phases, 120 checks |

> The original 2026-08-22 artifacts (34df640c… / 20985523… / 9801e05e…) were
> found deleted later that day and could not be reclaimed — these are fresh
> publishes of the same committed HTML. If a link here ever 404s again,
> republish from these files and update this table plus the latest handoff.

> **2026-08-23 — host and admin are BUILT but NOT REPUBLISHED.** The shared
> tail gained the full-run report below, so `host-checklist.html` and
> `admin-checklist.html` in this folder are ahead of what is live. They were
> deliberately not pushed: a host run was in progress and it is not proven that
> republishing the page leaves the separately-published `data/state.json`
> alone. Capture the run first (press Copy report, paste it to a session,
> commit the snapshot), THEN republish these two. The guest doc had no answers
> yet, so it was safe to republish and is live and current.

Each page colour-codes pass / fail / blocked and has a **Copy report** button.
It emits markdown of everything failing, and then — since 2026-08-23 — a
**Full run** appendix: one `PASS`/`FAIL`/`BLOCK` line per answered check.

That appendix exists because a Claude session **cannot read a run's results**.
Answers live in the artifact's `data/state.json`, which is private to the
owner's signed-in browser: `WebFetch` on it returns the page, the versioned
`/_f/…/data/state.json` path 403s, and the in-app browser is not signed in to
claude.ai. Copy report is the only channel. Emitting failures alone meant a run
where 120 checks passed left no record that they had been tested at all.

**Answers save into the artifact itself** (since 2026-08-22). `localStorage`
is only a cache — the viewer's sandboxing kept resetting it and the user kept
losing their marks. Every change is debounced into
`artifact.publish({"data/state.json": …})` via the artifact runtime capability
(declared as `capabilities: {artifact: {}}` at publish; the declaration is
stored, so later republishes that omit `capabilities` keep it — never pass
`{}`, that clears it). On open the page merges the served `data/state.json`
with the local cache per answer by timestamp (a Reset writes a `__cleared`
tombstone so an old cache cannot resurrect wiped answers) and pushes any
local-only marks back up. The chip in the top bar says which mode the page is
in: "Saved to doc ✓" / "Saving…" / "Local only" (outside claude.ai or on a
read-only view). Copy report remains the sure way to hand failures to a
Claude session.

## Files

| File | What |
|---|---|
| `_shell_head.txt` | Page chrome + CSS, up to the `const DATA` line |
| `_shell_tail.txt` | State, durable saves, rendering, filters, Copy report |
| `_host_data.js`, `_renter_data.js`, `_admin_data.js` | Each doc's `DATA` **plus its `LEGACY_KEYS` remap** |
| `build.cjs` | Stitches head + data + tail into ALL THREE pages |
| `*-checklist.html` | The built pages, as published |
| `stable_keys.py` | One-off: migrated all three off positional storage keys |
| `fix_legacy_map.py` | One-off: rebuilt the host legacy map to survive a section rename |
| `test_migration.cjs` | Proves saved answers land on the checks they were recorded against |
| `host-checklist.bak.html` | The pre-2026-08-22 host doc. Only `test_migration.cjs` reads it — it is the ordering the legacy keys were recorded against |

**All three docs build from the shell now** — the host is no longer a
hand-edited special case (the shell had gone stale against it once, still
carrying the retired positional-key scheme, and a rebuild would have silently
regressed guest and admin). Edit the data files, run `node build.cjs`, never
edit a built page directly.

## Data shape

```js
{ t: "Section title", d: "One-line description", items: [
  ["Check title", "What to do", "/api/endpoint", "/second/endpoint", "What should happen"],
]}
```

Every item is exactly five strings. Endpoints may be `""`.

## Editing rules

**Storage keys are `"<section title>::<check title>"`.** They used to be
`"<sectionIndex>|<itemIndex>"`, which meant inserting a row mid-section moved
every answer below it onto the wrong check — a document quietly claiming the
user had tested things they had not.

So:

1. **Check titles must stay unique across the whole document.** A duplicate
   silently merges two checks' answers. Verify after editing:

   ```bash
   node -e "const fs=require('fs'),vm=require('vm');const m=fs.readFileSync('host-checklist.html','utf8').match(/const DATA = \[[\s\S]*?\n\];/);const c={};vm.createContext(c);vm.runInContext(m[0]+';globalThis.__d=DATA;',c);const k=new Set(),d=[];c.__d.forEach(s=>s.items.forEach(i=>{const key=s.t+'::'+i[0];if(k.has(key))d.push(key);k.add(key);}));console.log(k.size+' keys, '+d.length+' duplicates',d)"
   ```

2. **Renaming a section or a check orphans its answers.** Prefer adding a new
   check to rewording an existing one. If a rename is unavoidable, extend the
   `LEGACY_KEYS` map in the page so the old key still resolves.

3. **Republish to the same URL** — pass the existing artifact URL as `url`, or
   the update creates a second artifact and the user loses their answers.

## Rebuilding all three

```bash
node build.cjs
```

Scripts are `.cjs`, not `.js`: the repo root `package.json` sets
`"type": "module"`, so a `.js` file here is parsed as an ES module and
`require` throws.

To re-run the key-migration proof:

```bash
node test_migration.cjs
```

It should report `misplaced: 0` and `leftover positional keys: 0`. The one
"gone from the checklist" line is expected — that check was split into two.
