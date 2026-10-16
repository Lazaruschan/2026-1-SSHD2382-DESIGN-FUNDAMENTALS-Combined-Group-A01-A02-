#!/usr/bin/env python3
"""Export SSHD2382 Marp lecture decks to self-contained HTML in slides/.

Sources: Notes/Design_Fundamentals/Design_Fundamentals/SSHD2382_Design_Fundamentals_week_NN[_MM]_*.md
Output:  slides/week-NN.html, or slides/week-NN-MM.html for combined decks.
Weeks 12+ are presentation weeks and are skipped.
"""

from __future__ import annotations

import importlib.util
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BASE = ROOT.parent.parent
SRC = BASE / "Notes" / "Design_Fundamentals" / "Design_Fundamentals"
IMG = BASE / "Notes" / "Design_Fundamentals" / "images"
OUT = ROOT / "slides"
STAGE = ROOT / ".slide-stage"
MARP_JS = ROOT / "node_modules" / "@marp-team" / "marp-cli" / "marp-cli.js"
WEEK_RE = re.compile(r"week_(\d+)(?:_(\d+))?_")
AUTH_TAG = '<script src="../auth.js"></script>'


def load_embedder():
    spec = importlib.util.spec_from_file_location("embed_slide_assets", ROOT / "embed-slide-assets.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def slug_for(md: Path) -> str | None:
    m = WEEK_RE.search(md.name)
    if not m:
        return None
    first = int(m.group(1))
    if first >= 12:
        print(f"[skip] week {first} (presentation week, no published deck)")
        return None
    slug = f"week-{first:02d}"
    if m.group(2):
        slug += f"-{int(m.group(2)):02d}"
    return slug


def main() -> int:
    if not MARP_JS.is_file():
        npm = shutil.which("npm") or "npm"
        subprocess.run([npm, "install"], cwd=ROOT, check=True)

    shutil.rmtree(STAGE, ignore_errors=True)
    STAGE.mkdir(parents=True)
    OUT.mkdir(exist_ok=True)
    # Copy (do not symlink) so cleanup cannot follow a link into Notes/images.
    shutil.copytree(IMG, STAGE / "images")

    produced: list[Path] = []
    for md in sorted(SRC.glob("SSHD2382_Design_Fundamentals_week_*.md")):
        slug = slug_for(md)
        if not slug:
            continue
        staged = STAGE / f"{slug}.md"
        staged.write_text(md.read_text(encoding="utf-8").replace("../images/", "./images/"), encoding="utf-8")
        out_html = OUT / f"{slug}.html"
        print(f"[marp] {md.name} -> slides/{out_html.name}")
        subprocess.run(
            ["node", str(MARP_JS), str(staged), "-o", str(out_html), "--html", "--allow-local-files"],
            cwd=ROOT,
            check=True,
        )
        produced.append(out_html)

    embedder = load_embedder()
    missing_total = 0
    for html in produced:
        replaced, missing = embedder.embed_html(html, [STAGE, OUT])
        missing_total += missing
        print(f"[embed] {html.name}: {replaced} assets inlined, {missing} missing")
        text = html.read_text(encoding="utf-8")
        if AUTH_TAG not in text and "</body>" in text:
            html.write_text(text.replace("</body>", f"{AUTH_TAG}</body>", 1), encoding="utf-8")

    keep = {p.name for p in produced}
    for stale in OUT.glob("week-*.html"):
        if stale.name not in keep:
            stale.unlink()
            print(f"[clean] removed stale {stale.name}")

    shutil.rmtree(STAGE, ignore_errors=True)
    shutil.rmtree(OUT / "images", ignore_errors=True)
    shutil.rmtree(OUT / "diagrams", ignore_errors=True)

    if missing_total:
        print(f"[warn] {missing_total} local image references could not be found")
    print(f"Exported {len(produced)} self-contained lecture decks to {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
