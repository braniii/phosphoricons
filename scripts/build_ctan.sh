#!/usr/bin/env bash
# Build the CTAN upload archive: phosphoricons.zip containing a single
# top-level phosphoricons/ directory with the package tree, README and
# LICENSE. The documentation PDF must already be built (scripts/build_doc.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/ctan"

[ -f "$ROOT/phosphoricons/doc/phosphoricons.pdf" ] \
    || { echo "error: doc PDF missing - run scripts/build_doc.sh first"; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT/phosphoricons"
cp -R "$ROOT/phosphoricons/tex" "$ROOT/phosphoricons/truetype" \
      "$ROOT/phosphoricons/tfm" "$ROOT/phosphoricons/enc" \
      "$ROOT/phosphoricons/map" "$ROOT/phosphoricons/doc" \
      "$OUT/phosphoricons/"
cp "$ROOT/README.md" "$ROOT/LICENSE" "$OUT/phosphoricons/"
find "$OUT" -name '*.png' -delete

(cd "$OUT" && zip -qr phosphoricons.zip phosphoricons)
echo "built $OUT/phosphoricons.zip"
