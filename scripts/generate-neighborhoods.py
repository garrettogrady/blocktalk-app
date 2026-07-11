#!/usr/bin/env python3
"""Build a clean, non-overlapping neighborhood partition from NYC 2020 NTAs.
Dissolves NTAs into colloquial neighborhoods (primary short names), simplifies,
and emits: neighborhood-polygons.json (name+rings) + a Swift directory snippet."""
import json, re, sys
from collections import defaultdict
from shapely.geometry import shape, mapping, Polygon, MultiPolygon
from shapely.ops import unary_union

SRC = "/Users/mattb/Documents/blocktalk-react/blocktalk/assets/data/nyc-ntas.geojson"
OUT_JSON = "/private/tmp/claude-502/-Users-mattb-Documents-blocktalk/21ff894b-dabd-450c-b31a-e9e2c2f984d2/scratchpad/neighborhood-polygons.json"
OUT_SWIFT = "/private/tmp/claude-502/-Users-mattb-Documents-blocktalk/21ff894b-dabd-450c-b31a-e9e2c2f984d2/scratchpad/directory.swift"

SIMPLIFY_TOL = 0.00018   # ~20m; balances shape fidelity vs file size
MIN_RING_PTS = 4
MIN_PART_AREA = 3e-6     # drop tiny multipolygon slivers (deg^2, ~ small block)

# NTA primary name -> preferred display name (only where first-segment isn't ideal)
NAME_OVERRIDE = {
    "Midtown South-Flatiron-Union Square": "Flatiron",
    "Manhattanville-West Harlem": "Manhattanville",
    "Co-op City": "Co-op City",  # hyphen isn't a separator here
}
# display name -> short code (well-known; others auto-generated)
CODE_OVERRIDE = {
    "Lower East Side": "LES", "SoHo": "SOHO", "Financial District": "FIDI",
    "East Village": "EV", "Greenwich Village": "GV", "West Village": "WV",
    "Upper East Side": "UES", "Upper West Side": "UWS", "Tribeca": "TRIBECA",
    "Chelsea": "CHELSEA", "Chinatown": "C-TOWN", "Harlem": "HARLEM",
    "East Harlem": "E.HARLEM", "Hell's Kitchen": "HK", "Midtown": "MIDTOWN",
    "Midtown South": "MID.S", "Flatiron": "FLATIRON", "Gramercy": "GRAMERCY",
    "Murray Hill": "MURRAY", "Morningside Heights": "MORNING", "Inwood": "INWOOD",
    "Washington Heights": "WASH.HTS", "Hamilton Heights": "HAM.HTS",
    "East Midtown": "E.MID", "Stuyvesant Town": "STUY.TOWN", "Manhattanville": "M.VILLE",
    "Williamsburg": "WILLYB", "Astoria": "ASTORIA", "Park Slope": "SLOPE",
    "DUMBO": "DUMBO", "Greenpoint": "GPOINT", "Red Hook": "RED HOOK",
}

def primary_name(ntaname):
    if ntaname in NAME_OVERRIDE:
        return NAME_OVERRIDE[ntaname]
    base = re.sub(r"\(.*?\)", "", ntaname).strip()
    first = base.split("-")[0].strip()
    # guard: a 1-2 char first segment means the hyphen wasn't a separator
    return first if len(first) > 2 else base

def short_code(name):
    if name in CODE_OVERRIDE:
        return CODE_OVERRIDE[name]
    words = [w for w in re.split(r"[\s\-]+", name) if w]
    if len(words) == 1:
        return words[0].upper()           # full word, no ugly truncation
    return "".join(w[0] for w in words).upper()[:6]

def rings_from_geom(geom):
    """Exterior rings only (drop holes), simplified, in [lng,lat] order."""
    geom = geom.simplify(SIMPLIFY_TOL, preserve_topology=True)
    parts = geom.geoms if isinstance(geom, MultiPolygon) else [geom]
    rings = []
    for p in parts:
        if p.is_empty or p.area < MIN_PART_AREA:
            continue
        coords = [[round(x, 5), round(y, 5)] for x, y in p.exterior.coords]
        if len(coords) >= MIN_RING_PTS:
            rings.append(coords)
    return rings

def main():
    data = json.load(open(SRC))
    res = [f for f in data["features"] if f["properties"].get("ntatype") == "0"]

    # group NTA geometries by (borough, display name)
    groups = defaultdict(lambda: {"geoms": [], "boro": None})
    for f in res:
        p = f["properties"]
        name = primary_name(p["ntaname"])
        key = (p["boroname"], name)
        groups[key]["geoms"].append(shape(f["geometry"]))
        groups[key]["boro"] = p["boroname"]

    # disambiguate names that collide across boroughs
    name_counts = defaultdict(set)
    for (boro, name) in groups:
        name_counts[name].add(boro)
    BORO_PRIORITY = ["Manhattan", "Brooklyn", "Queens", "Bronx", "Staten Island"]
    def display(boro, name):
        if len(name_counts[name]) > 1:
            # highest-priority borough keeps the bare name; others get a suffix
            top = min(name_counts[name], key=lambda b: BORO_PRIORITY.index(b))
            if boro != top:
                return f"{name} ({boro})"
        return name

    out = []
    dir_entries = []
    dissolved = {}  # name -> shapely geom (for overlap validation)
    for (boro, name), v in sorted(groups.items(), key=lambda kv: (kv[0][0], kv[0][1])):
        geom = unary_union(v["geoms"])
        disp = display(boro, name)
        rings = rings_from_geom(geom)
        if not rings:
            continue
        out.append({"name": disp, "rings": rings})
        dir_entries.append((disp, short_code(name), boro))
        dissolved[disp] = geom

    out.sort(key=lambda e: e["name"])
    json.dump(out, open(OUT_JSON, "w"))

    # Swift directory snippet, grouped by borough
    boros = ["Manhattan", "Brooklyn", "Queens", "Bronx", "Staten Island"]
    lines = []
    by_boro = defaultdict(list)
    for name, code, boro in dir_entries:
        by_boro[boro].append((name, code))
    for boro in boros:
        lines.append(f"        // {boro}")
        for name, code in sorted(by_boro[boro]):
            nm = name.replace('"', '\\"')
            lines.append(f'        Entry(name: "{nm}", shortCode: "{code}", borough: "{boro}"),')
        lines.append("")
    open(OUT_SWIFT, "w").write("\n".join(lines))

    # ---- validation ----
    import itertools
    npts = sum(len(r) for e in out for r in e["rings"])
    print(f"neighborhoods: {len(out)}  |  total points: {npts}")
    import os
    print(f"json size: {os.path.getsize(OUT_JSON)/1024:.0f} KB")
    by = defaultdict(int)
    for _, _, b in dir_entries:
        by[b] += 1
    print("by borough:", dict(by))
    # pairwise overlap check (area of intersection relative to smaller)
    names = list(dissolved)
    worst = []
    for a, b in itertools.combinations(names, 2):
        ga, gb = dissolved[a], dissolved[b]
        if not ga.envelope.intersects(gb.envelope):
            continue
        inter = ga.intersection(gb).area
        if inter > 1e-7:  # meaningful overlap (not just a shared edge)
            rel = inter / min(ga.area, gb.area)
            worst.append((rel, a, b, inter))
    worst.sort(reverse=True)
    print(f"\noverlapping pairs (>tiny): {len(worst)}")
    for rel, a, b, inter in worst[:8]:
        print(f"  {rel*100:.2f}% overlap: {a}  <->  {b}")
    # Manhattan list
    print("\n=== Manhattan neighborhoods ===")
    for name, code, boro in sorted(dir_entries):
        if boro == "Manhattan":
            print(f"  {name:22} {code}")

if __name__ == "__main__":
    main()
