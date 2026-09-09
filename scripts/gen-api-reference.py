#!/usr/bin/env python3
"""Generate Documentation/APIReference.md from the DocC symbol graph.

Usage:
    swift package dump-symbol-graph --minimum-access-level public
    python3 scripts/gen-api-reference.py > Documentation/APIReference.md
"""
import collections
import glob
import json
import re
import sys

graphs = glob.glob(".build/**/symbolgraph/SwiftNetworkKit.symbols.json", recursive=True)
if not graphs:
    sys.exit("No symbol graph. Run: swift package dump-symbol-graph --minimum-access-level public")
g = json.load(open(sorted(graphs)[0]))
syms = g["symbols"]
by_id = {s["identifier"]["precise"]: s for s in syms}

children = collections.defaultdict(list)
for r in g["relationships"]:
    if r["kind"] == "memberOf":
        children[r["target"]].append(r["source"])

TYPE_KINDS = {
    "swift.class": "class", "swift.struct": "struct", "swift.enum": "enum",
    "swift.protocol": "protocol", "swift.actor": "actor", "swift.typealias": "typealias",
}

AREA = {
    "Core": "Core", "HTTP": "Core", "Environment": "Environment",
    "Transport": "Transport & connectivity", "Connectivity": "Transport & connectivity",
    "Authentication": "Authentication", "OAuth": "OAuth 2.0",
    "Retry": "Resilience", "Clock": "Resilience",
    "Offline": "Offline queue", "Cache": "Caching",
    "Interceptors": "Interceptors & observability", "Logging": "Interceptors & observability",
    "Metrics": "Interceptors & observability", "Tracing": "Interceptors & observability",
    "Security": "Security & pinning", "Upload": "Transfers", "Pagination": "Pagination",
    "SwiftUI": "Combine & SwiftUI", "Combine": "Combine & SwiftUI",
    "RequestManagement": "Request management", "Testing": "Testing utilities",
}
ORDER = [
    "Core", "Environment", "Authentication", "OAuth 2.0", "Resilience", "Caching",
    "Offline queue", "Transport & connectivity", "Interceptors & observability",
    "Security & pinning", "Transfers", "Pagination", "Combine & SwiftUI",
    "Request management", "Testing utilities", "Other",
]


def area_of(sym):
    uri = sym.get("location", {}).get("uri", "")
    m = re.search(r"Sources/SwiftNetworkKit/([^/]+)/", uri)
    return AREA.get(m.group(1), "Other") if m else "Other"


def summary(sym):
    doc = sym.get("docComment")
    if not doc:
        return ""
    text = " ".join(ln["text"].strip() for ln in doc["lines"]).strip()
    # normalise dashes to house style (no em/en dashes in tracked docs)
    em, en = chr(0x2014), chr(0x2013)
    text = text.replace(f" {em} ", ", ").replace(em, ", ").replace(en, "-").replace(" - ", ", ")
    text = re.sub(r"\s*\((?:M\d+|Milestone\s*\d+)\)", "", text)  # house style: no milestone refs
    text = re.sub(r",\s*,", ",", text)
    m = re.match(r"(.+?[.!?])(\s|$)", text)
    return (m.group(1) if m else text)[:280]


def member_name(sym):
    return sym.get("pathComponents", ["?"])[-1]


types = [s for s in syms
         if s["kind"]["identifier"] in TYPE_KINDS and len(s.get("pathComponents", [])) == 1]
groups = collections.defaultdict(list)
for t in types:
    groups[area_of(t)].append(t)

out = []
out.append("# SwiftNetworkKit Public API Reference\n")
out.append(
    f"Generated from the DocC symbol graph. {len(types)} public types. "
    "Regenerate after any public-API change:\n\n"
    "```bash\n"
    "swift package dump-symbol-graph --minimum-access-level public\n"
    "python3 scripts/gen-api-reference.py > Documentation/APIReference.md\n"
    "```\n"
)
out.append("| Area | Types |")
out.append("|---|---|")
for area in ORDER:
    if area in groups:
        names = ", ".join(f"`{t['pathComponents'][0]}`"
                          for t in sorted(groups[area], key=lambda x: x["pathComponents"][0]))
        out.append(f"| {area} | {names} |")
out.append("")

for area in ORDER:
    if area not in groups:
        continue
    out.append(f"## {area}\n")
    for t in sorted(groups[area], key=lambda x: x["pathComponents"][0]):
        name = t["pathComponents"][0]
        kind = TYPE_KINDS[t["kind"]["identifier"]]
        out.append(f"### `{name}`  `{kind}`\n")
        s = summary(t)
        if s:
            out.append(s + "\n")
        kids = [by_id[c] for c in children.get(t["identifier"]["precise"], []) if c in by_id]
        cases = sorted({member_name(k) for k in kids if k["kind"]["identifier"] == "swift.enum.case"})
        props = sorted({member_name(k) for k in kids
                        if k["kind"]["identifier"] in ("swift.property", "swift.type.property")})
        meths = sorted({member_name(k) for k in kids
                        if k["kind"]["identifier"] in ("swift.method", "swift.type.method")})
        if cases:
            out.append("**Cases:** " + ", ".join(f"`.{c}`" for c in cases) + "\n")
        if props:
            shown = props[:14]
            extra = f" _(+{len(props) - len(shown)} more)_" if len(props) > len(shown) else ""
            out.append("**Properties:** " + ", ".join(f"`{p}`" for p in shown) + extra + "\n")
        if meths:
            shown = meths[:14]
            extra = f" _(+{len(meths) - len(shown)} more)_" if len(meths) > len(shown) else ""
            out.append("**Methods:** " + ", ".join(f"`{m}()`" for m in shown) + extra + "\n")
    out.append("")

print("\n".join(out))
