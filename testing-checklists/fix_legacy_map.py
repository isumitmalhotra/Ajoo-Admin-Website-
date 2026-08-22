# -*- coding: utf-8 -*-
"""
Rebuild the legacy key map so a RENAMED section doesn't orphan its ticks.

The first version mapped old position -> "<old section title>::<check title>".
That is right only while section titles hold still, and one was renamed in this
pass ("Regression — today's fixes" became "Regression — earlier fixes" when the
new feedback section took its place). Every tick in it would have been dropped.

Mapping now resolves each old check against the NEW data by its check title,
so it survives a section rename and a check moving between sections. A check
that genuinely no longer exists maps to nothing and its tick is discarded,
which is correct — there is nothing left for it to describe.
"""
import io, json, re, subprocess

def read_data(path):
    src = io.open(path, encoding="utf-8").read()
    m = re.search(r"const DATA = \[[\s\S]*?\n\];", src)
    assert m, path
    js = (m.group(0).replace("const DATA = ", "const DATA = ").rstrip(";")
          + ";process.stdout.write(JSON.stringify(DATA.map(s=>[s.t,s.items.map(i=>i[0])])));")
    out = subprocess.run(["node", "-e", js], capture_output=True, text=True,
                         encoding="utf-8")
    if out.returncode:
        raise SystemExit(path + ": " + out.stderr)
    return json.loads(out.stdout)


OLD = read_data("host-checklist.bak.html")
NEW = read_data("host-checklist.html")

# Where each check title lives now. Titles are unique across the document;
# assert it rather than trust it, because a duplicate would silently send one
# check's answers to the other.
where = {}
dupes = []
for sec, items in NEW:
    for title in items:
        if title in where:
            dupes.append(title)
        where[title] = "%s::%s" % (sec, title)
assert not dupes, "duplicate check titles in new data: %s" % dupes

legacy, dropped = {}, []
for si, (sec, items) in enumerate(OLD):
    for ii, title in enumerate(items):
        target = where.get(title)
        if target:
            legacy["%d|%d" % (si, ii)] = target
        else:
            dropped.append("%s / %s" % (sec, title))

p = "host-checklist.html"
s = io.open(p, encoding="utf-8").read()
m = re.search(r"const LEGACY_KEYS=\{[\s\S]*?\};", s)
assert m, "LEGACY_KEYS not found"
s = s[:m.start()] + "const LEGACY_KEYS=" + json.dumps(legacy, ensure_ascii=False) + ";" + s[m.end():]
io.open(p, "w", encoding="utf-8").write(s)

print("mapped %d of %d old checks" % (len(legacy), sum(len(i) for _, i in OLD)))
if dropped:
    print("no longer in the checklist (ticks discarded):")
    for d in dropped:
        print("  -", d)
