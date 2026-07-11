#!/usr/bin/env python3
"""Build a clean, non-overlapping neighborhood partition from the Pediacities
NYC Neighborhoods dataset (colloquial names: Two Bridges, Nolita, etc.).
Merges multi-part features, erases the few overlaps into a true partition,
simplifies, and emits neighborhood-polygons.json + a Swift directory snippet."""
import json, re, itertools, os
from collections import defaultdict
from shapely.geometry import shape, MultiPolygon, Polygon
from shapely.ops import unary_union
from shapely.validation import make_valid

SRC = "scripts/data/nyc-neighborhoods-source.geojson"
OUT_JSON = "BlockTalk/Resources/neighborhood-polygons.json"
OUT_SWIFT = "scripts/data/directory.swift"

SIMPLIFY_TOL = 0.00018
MIN_RING_PTS = 4
MIN_PART_AREA = 3e-6

CODE_OVERRIDE = {
    "Lower East Side": "LES", "SoHo": "SOHO", "Financial District": "FIDI",
    "East Village": "EV", "Greenwich Village": "GV", "West Village": "WV",
    "Upper East Side": "UES", "Upper West Side": "UWS", "Tribeca": "TRIBECA",
    "Chelsea": "CHELSEA", "Chinatown": "C-TOWN", "Harlem": "HARLEM",
    "East Harlem": "E.HARLEM", "Hell's Kitchen": "HK", "Midtown": "MIDTOWN",
    "Flatiron District": "FLATIRON", "Gramercy": "GRAMERCY", "Murray Hill": "MURRAY",
    "Morningside Heights": "MORNING", "Inwood": "INWOOD", "Washington Heights": "WASH.HTS",
    "Hamilton Heights": "HAM.HTS", "Stuyvesant Town": "STUY", "Two Bridges": "TWO.BR",
    "Nolita": "NOLITA", "NoHo": "NOHO", "Little Italy": "L.ITALY", "Kips Bay": "KIPS",
    "Battery Park City": "BPC", "Civic Center": "CIVIC", "Theater District": "THEATER",
    "Roosevelt Island": "ROOSVLT", "Marble Hill": "MARBLE", "Central Park": "C.PARK",
    "Williamsburg": "WILLYB", "East Williamsburg": "E.WBURG", "Greenpoint": "GPOINT",
    "Park Slope": "SLOPE", "Cobble Hill": "COBBLE", "Carroll Gardens": "CARROLL",
    "Red Hook": "RED HOOK", "DUMBO": "DUMBO", "Astoria": "ASTORIA",
}

def short_code(name):
    if name in CODE_OVERRIDE:
        return CODE_OVERRIDE[name]
    words = [w for w in re.split(r"[\s\-]+", name) if w]
    if len(words) == 1:
        return words[0].upper()
    return "".join(w[0] for w in words).upper()[:6]

def rings_from_geom(geom):
    geom = geom.simplify(SIMPLIFY_TOL, preserve_topology=True)
    parts = geom.geoms if isinstance(geom, MultiPolygon) else [geom]
    rings = []
    for p in parts:
        if not isinstance(p, Polygon) or p.is_empty or p.area < MIN_PART_AREA:
            continue
        coords = [[round(x, 5), round(y, 5)] for x, y in p.exterior.coords]
        if len(coords) >= MIN_RING_PTS:
            rings.append(coords)
    return rings

def main():
    data = json.load(open(SRC))
    # merge features by (name) -> union of parts, tracking borough
    merged = {}
    boro = {}
    for f in data["features"]:
        name = f["properties"]["neighborhood"]
        b = f["properties"]["borough"]
        g = shape(f["geometry"])
        if not g.is_valid:
            g = make_valid(g)
        merged[name] = g if name not in merged else unary_union([merged[name], g])
        boro[name] = b

    # ---- resolve overlaps: greedy erase, smallest-area first (dense/small
    #      neighborhoods keep their full shape; larger ones cede the sliver) ----
    order = sorted(merged, key=lambda n: merged[n].area)
    placed = None
    clean = {}
    for name in order:
        g = merged[name]
        if placed is not None and g.intersects(placed):
            g = g.difference(placed)
        if g.is_empty:
            continue
        # keep only polygonal parts
        if g.geom_type == "GeometryCollection":
            polys = [p for p in g.geoms if isinstance(p, (Polygon, MultiPolygon))]
            g = unary_union(polys) if polys else None
            if g is None or g.is_empty:
                continue
        clean[name] = g
        placed = g if placed is None else unary_union([placed, g])

    # cross-borough name disambiguation (priority borough keeps bare name)
    PRI = ["Manhattan", "Brooklyn", "Queens", "Bronx", "Staten Island"]
    boros_for = defaultdict(set)
    for name in clean:
        boros_for[name].add(boro[name])
    def display(name):
        bs = boros_for[name]
        if len(bs) > 1:
            top = min(bs, key=lambda b: PRI.index(b))
            if boro[name] != top:
                return f"{name} ({boro[name]})"
        return name

    out, dir_entries, geoms = [], [], {}
    for name in sorted(clean):
        rings = rings_from_geom(clean[name])
        if not rings:
            continue
        disp = display(name)
        out.append({"name": disp, "rings": rings})
        dir_entries.append((disp, short_code(name), boro[name]))
        geoms[disp] = clean[name]

    out.sort(key=lambda e: e["name"])
    json.dump(out, open(OUT_JSON, "w"))

    # Swift directory grouped by borough
    by_boro = defaultdict(list)
    for name, code, b in dir_entries:
        by_boro[b].append((name, code))
    lines = []
    for b in PRI:
        lines.append(f"        // {b}")
        for name, code in sorted(by_boro[b]):
            lines.append(f'        Entry(name: "{name}", shortCode: "{code}", borough: "{b}"),')
        lines.append("")
    open(OUT_SWIFT, "w").write("\n".join(lines))

    # validate
    npts = sum(len(r) for e in out for r in e["rings"])
    print(f"neighborhoods: {len(out)} | points: {npts} | json: {os.path.getsize(OUT_JSON)/1024:.0f} KB")
    print("by borough:", {b: len(by_boro[b]) for b in PRI})
    names = list(geoms)
    worst = []
    for a, c in itertools.combinations(names, 2):
        ga, gc = geoms[a], geoms[c]
        if not ga.envelope.intersects(gc.envelope):
            continue
        inter = ga.intersection(gc).area
        if inter > 1e-7:
            worst.append((inter/min(ga.area, gc.area), a, c))
    worst.sort(reverse=True)
    print(f"overlapping pairs after cleaning: {len(worst)}")
    for rel, a, c in worst[:6]:
        print(f"   {rel*100:.2f}%  {a} <-> {c}")
    print("\n=== Manhattan ===")
    for name, code, b in sorted(dir_entries):
        if b == "Manhattan":
            print(f"  {name:22} {code}")

if __name__ == "__main__":
    main()
