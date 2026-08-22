# Testing checklists

The three interactive QA documents published as Claude artifacts. Sources live
here so a future session can update them instead of rebuilding from scratch —
they were previously only in a session scratchpad, which does not survive.

| Doc | Published at | Size |
|---|---|---|
| Host readiness | https://claude.ai/code/artifact/34df640c-ea5a-45b3-8c90-e65768b595f7 | 13 phases, 125 checks |
| Guest readiness | https://claude.ai/code/artifact/20985523-4e8d-4d14-b76e-195e0633f9e7 | 14 phases, 101 checks |
| Admin readiness | https://claude.ai/code/artifact/9801e05e-06d3-4012-a843-3761533d440e | 14 phases, 119 checks |

Each page keeps its answers in the browser's `localStorage`, colour-codes
pass / fail / blocked, and has a **Copy report** button that emits markdown of
everything failing. **Answers cannot be read from a Claude session** — the user
has to press Copy report and paste it.

## Files

| File | What |
|---|---|
| `_shell_head.txt` | Page chrome + CSS, up to the `const DATA` line |
| `_shell_tail.txt` | Rendering, state, filters, Copy report |
| `_renter_data.js`, `_admin_data.js` | The check data for guest and admin |
| `build.cjs` | Stitches head + data + tail into the guest and admin pages |
| `*-checklist.html` | The built pages, as published |
| `stable_keys.py` | One-off: migrated all three off positional storage keys |
| `fix_legacy_map.py` | One-off: rebuilt the host legacy map to survive a section rename |
| `test_migration.cjs` | Proves saved answers land on the checks they were recorded against |
| `host-checklist.bak.html` | The pre-2026-08-22 host doc. Only `test_migration.cjs` reads it — it is the ordering the legacy keys were recorded against |

**The host data is inline in `host-checklist.html`** — there is no
`_host_data.js`, so `build.cjs` does not build it. Edit the `const DATA` array
in the HTML directly.

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

## Rebuilding guest and admin

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
