# -*- coding: utf-8 -*-
"""
Move the checklist's saved state off positional keys.

State was stored as "<sectionIndex>|<itemIndex>". That is fine until the
checklist gains a row — which it just did, in the middle of several sections —
at which point every tick below the insertion point silently belongs to the
wrong check. Someone who had worked through the list would come back to a
document quietly claiming they had tested things they had not.

Keys become "<section title>::<check title>", which survive insertion,
reordering and renumbering. A one-time migration reads whatever is in the old
scheme and rewrites it through the OLD ordering, so existing ticks land on the
checks they were actually recorded against.
"""
import io, json, re, subprocess, sys

TARGETS = [
    ("host-checklist.html", "host-checklist.bak.html"),
    ("guest-checklist.html", None),
    ("admin-checklist.html", None),
]


def read_data(path):
    """Pull the DATA literal out of a built checklist and evaluate it."""
    src = io.open(path, encoding="utf-8").read()
    m = re.search(r"const DATA = \[[\s\S]*?\n\];", src)
    assert m, path
    js = (
        "const DATA = " + m.group(0).replace("const DATA = ", "").rstrip(";")
        + ";process.stdout.write(JSON.stringify(DATA.map(s=>[s.t,s.items.map(i=>i[0])])));"
    )
    out = subprocess.run(["node", "-e", js], capture_output=True, text=True,
                         encoding="utf-8")
    if out.returncode:
        raise SystemExit(path + ": " + out.stderr)
    return json.loads(out.stdout)


for path, backup in TARGETS:
    src = io.open(path, encoding="utf-8").read()
    if "MIGRATED_TO_STABLE_KEYS" in src:
        print("already migrated:", path)
        continue

    # The ordering the existing saved state was recorded against. For the host
    # doc that is the pre-edit backup; the other two are unchanged.
    old = read_data(backup or path)
    legacy = {}
    for si, (_sec, items) in enumerate(old):
        for ii, _title in enumerate(items):
            legacy["%d|%d" % (si, ii)] = "%s::%s" % (old[si][0], items[ii])

    old_line = 'const id=(s,i)=>s+"|"+i;'
    assert src.count(old_line) == 1, path
    new_line = (
        "// MIGRATED_TO_STABLE_KEYS — see stable_keys.py.\n"
        "// Keys are the section and check titles, not their positions, so\n"
        "// adding a row no longer moves everyone's answers down one.\n"
        "const id=(s,i)=>DATA[s].t+\"::\"+DATA[s].items[i][0];\n"
        "// One-time remap of anything saved under the old positional keys,\n"
        "// through the ordering those keys were recorded against.\n"
        "const LEGACY_KEYS=" + json.dumps(legacy, ensure_ascii=False) + ";\n"
        "(function(){\n"
        "  let moved=0;\n"
        "  for(const k of Object.keys(state)){\n"
        "    if(!k.includes(\"|\")) continue;\n"
        "    const to=LEGACY_KEYS[k];\n"
        "    if(to && state[to]===undefined){ state[to]=state[k]; moved++; }\n"
        "    delete state[k];\n"
        "  }\n"
        "  if(moved) save();\n"
        "})();"
    )
    src = src.replace(old_line, new_line)
    io.open(path, "w", encoding="utf-8").write(src)
    print("migrated:", path, "-", len(legacy), "legacy keys mapped")
