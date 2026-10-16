#!/usr/bin/env python3
"""Export SSHD2382 Group Activity worksheets (Marp markdown) to PDF in assets/worksheets/.

Sources: Group Activity/WeekNN[-MM]_Worksheet.md
Output:  assets/worksheets/week-NN.pdf, or week-NN-MM.pdf for two-week worksheets.
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BASE = ROOT.parent.parent
SRC = BASE / "Group Activity"
OUT = ROOT / "assets" / "worksheets"
STAGE = ROOT / ".worksheet-stage"
MARP_JS = ROOT / "node_modules" / "@marp-team" / "marp-cli" / "marp-cli.js"
WEEK_RE = re.compile(r"^Week(\d+)(?:-(\d+))?_Worksheet\.md$", re.IGNORECASE)


def slug_for(md: Path) -> str | None:
    m = WEEK_RE.match(md.name)
    if not m:
        return None
    slug = f"week-{int(m.group(1)):02d}"
    if m.group(2):
        slug += f"-{int(m.group(2)):02d}"
    return slug


def main() -> int:
    if not MARP_JS.is_file():
        npm = shutil.which("npm") or "npm"
        subprocess.run([npm, "install"], cwd=ROOT, check=True)

    OUT.mkdir(parents=True, exist_ok=True)
    shutil.rmtree(STAGE, ignore_errors=True)
    STAGE.mkdir(parents=True)

    slugs: dict[str, str] = {}
    for md in sorted(SRC.glob("Week*_Worksheet.md")):
        slug = slug_for(md)
        if slug:
            shutil.copy2(md, STAGE / md.name)
            slugs[md.stem] = slug

    # One Marp run for all files so the browser is launched only once.
    print(f"[marp] converting {len(slugs)} worksheets")
    subprocess.run(
        ["node", str(MARP_JS), "--input-dir", str(STAGE), "-o", str(STAGE),
         "--pdf", "--pdf-outlines", "--html", "--allow-local-files", "--browser-timeout", "300"],
        cwd=ROOT,
        check=True,
    )

    produced: list[Path] = []
    for stem, slug in slugs.items():
        out_pdf = OUT / f"{slug}.pdf"
        shutil.move(str(STAGE / f"{stem}.pdf"), out_pdf)
        print(f"[pdf] {stem}.md -> assets/worksheets/{out_pdf.name}")
        produced.append(out_pdf)
    shutil.rmtree(STAGE, ignore_errors=True)

    keep = {p.name for p in produced}
    for stale in OUT.glob("week-*.pdf"):
        if stale.name not in keep:
            stale.unlink()
            print(f"[clean] removed stale {stale.name}")

    print(f"Exported {len(produced)} worksheet PDFs to {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
