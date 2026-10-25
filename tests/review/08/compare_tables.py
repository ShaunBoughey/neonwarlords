# Compare GDD section 08 reward tables (review/gdd txt) with data/gdd.json
import json, re, sys
ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
lines = [l.rstrip("\n") for l in open(ROOT + "/review/gdd/08_resource-hideouts-deeds.txt", encoding="utf-8")]
cells = [re.sub(r"^\[[^\]]*\] ?", "", l).strip() for l in lines]
heads = {c: i for i, c in enumerate(cells) if c.startswith("Hideout:")}
def block(start, end):
    return cells[heads[start] + 1: heads[end] if end else len(cells)]
G = json.load(open(ROOT + "/data/gdd.json", encoding="utf-8"))
issues = []
def chk(tag, a, b):
    if a != b: issues.append(f"{tag}: GDD={a!r} code={b!r}")

# --- two-column tables (synapse, deeds): header 8 cells, then per stage pair: rows of 8 cells
def two_col(cs, nrows):
    cs = cs[8:]
    out = {}
    i = 0
    while i + 8 * nrows <= len(cs) and cs[i].isdigit():
        L = {"stage": int(cs[i]), "energy": int(cs[i + 3]), "rows": []}
        R = {"stage": int(cs[i + 4]), "energy": int(cs[i + 7]), "rows": []}
        for r in range(nrows):
            row = cs[i + 8 * r: i + 8 * r + 8]
            L["rows"].append([row[1], row[2]]); R["rows"].append([row[5], row[6]])
        out[L["stage"]] = L; out[R["stage"]] = R
        i += 8 * nrows
    return out

syn = two_col(block("Hideout: Synapse Centre Reward Table", "Hideout: Heist (Money)"), 3)
chk("synapse stage count", 20, len(syn))
for s, g in sorted(syn.items()):
    c = G["synapse"][s - 1]
    chk(f"synapse s{s} energy", g["energy"], c["energy"])
    for j, (gr, cr) in enumerate(zip(g["rows"], c["rows"])):
        norm = lambda v: "-".join(str(int(x)) for x in v.split("-"))
        chk(f"synapse s{s} row{j} tier", gr[0], cr[0])
        chk(f"synapse s{s} {gr[0]} amount", norm(gr[1]), norm(cr[1]))
        # sanity: range width 20
        p = [int(x) for x in gr[1].split("-")]
        if len(p) == 2 and p[1] - p[0] != 20: issues.append(f"GDD-NOTE synapse s{s} {gr[0]} range {gr[1]} width {p[1]-p[0]} (others are 20)")

deeds = two_col(block("Hideout: All Deeds Reward Tables", None), 5)
chk("deeds stage count", 20, len(deeds))
for s, g in sorted(deeds.items()):
    c = G["deeds"][s - 1]
    chk(f"deeds s{s} energy", g["energy"], c["energy"])
    for j, (gr, cr) in enumerate(zip(g["rows"], c["rows"])):
        chk(f"deeds s{s} row{j} reward", re.sub(r"(\d)C", r"\1 C", gr[0]), cr[0])
        chk(f"deeds s{s} row{j} chance", float(gr[1].rstrip("%")), float(str(cr[1]).rstrip("%")))
    mm = sum(float(r[1].rstrip("%")) for r in g["rows"][:3])
    if abs(mm - 100) > 0.01: issues.append(f"GDD-NOTE deeds s{s} minor+major+grand chances sum {mm}")

# --- heist: 4 cols, 7 rows per stage
hc = block("Hideout: Heist Reward Table", "Hideout: Chopshop (Implants)")[4:]
heist = {}
i = 0
while i < len(hc) and hc[i].isdigit():
    st = int(hc[i]); rows = []
    for r in range(7):
        row = hc[i + 4 * r: i + 4 * r + 4]; rows.append([row[1], float(row[2])])
        if r == 0: chk(f"heist s{st} cost", row[3], "1 Heist Plan")
    heist[st] = rows; i += 28
chk("heist stage count", 20, len(heist))
for s, rows in heist.items():
    c = G["heist"][s - 1]["rows"]
    chk(f"heist s{s} rows", rows, [[r[0], float(r[1])] for r in c])
    tot = sum(r[1] for r in rows)
    if abs(tot - 100) > 0.01: issues.append(f"GDD-NOTE heist s{s} chances sum {tot}")

# --- chopshop: 4 cols, variable rows per stage
cc = block("Hideout: Chopshop Reward Table", "Hideout: (Paragon Deeds)")[4:]
chop = {}
i = 0
while i < len(cc) and cc[i].isdigit():
    st = int(cc[i]); d = {"stage": st, "credits": int(re.search(r"(\d+) Credits", cc[i + 1]).group(1)),
                          "energy": int(cc[i + 3].split()[0]), "ranks": {}, "rar": {}, "slots": {}}
    j = i + 4
    while j < len(cc) and not cc[j].isdigit() and cc[j] == "":
        lab, val = cc[j + 1], cc[j + 2]
        if lab.startswith("Rank "): d["ranks"][lab.split()[1]] = int(val)
        elif lab.lower() in ("uncommon", "rare", "epic", "legendary", "common"): d["rar"][lab.lower()] = int(val)
        elif lab.lower() in ("limbs", "organs", "skeleton"): d["slots"][lab.lower()] = int(val)
        elif lab.startswith("1x Random"): d["label"] = lab
        j += 4
    chop[st] = d; i = j
    while i < len(cc) and cc[i] == "": i += 1
chk("chopshop stage count", 20, len(chop))
for s, g in chop.items():
    c = G["chopshop"][s - 1]
    for k in ("credits", "energy", "ranks", "rar", "slots"):
        chk(f"chopshop s{s} {k}", g[k], c[k])
    for k in ("ranks", "rar", "slots"):
        t = sum(g[k].values())
        if t != 100: issues.append(f"GDD-NOTE chopshop s{s} {k} sum {t}")
print("\n".join(issues) if issues else "ALL MATCH")
print("parsed:", len(syn), len(heist), len(chop), len(deeds))
