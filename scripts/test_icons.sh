#!/usr/bin/env bash
# Compile-test every icon in every weight on pdfLaTeX, XeLaTeX and LuaLaTeX,
# against the uninstalled package tree. Fails on any TeX error, undefined
# font shape, or missing character.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
P="$ROOT/phosphoricons"
WORK="$ROOT/build/test-icons"
mkdir -p "$WORK"
cp "$ROOT/scripts/test_icons.tex" "$WORK/"

export TEXINPUTS="$P/tex//:"
export TFMFONTS="$P/tfm//:"
export ENCFONTS="$P/enc//:"
export TTFONTS="$P/truetype//:"
export TEXFONTMAPS="$P/map//:"

fail=0
for eng in pdflatex xelatex lualatex; do
    echo "== $eng =="
    if ! (cd "$WORK" && $eng -interaction=nonstopmode -halt-on-error \
            test_icons.tex > /dev/null 2>&1); then
        echo "   COMPILE FAILED"
        grep -A2 '^!' "$WORK/test_icons.log" | head -20 || true
        fail=1
        continue
    fi
    shapes=$(grep -c 'Font shape.*undefined' "$WORK/test_icons.log" || true)
    missing=$(grep -c 'Missing character' "$WORK/test_icons.log" || true)
    echo "   ok  (undefined shapes: $shapes, missing characters: $missing)"
    if [ "$shapes" != 0 ] || [ "$missing" != 0 ]; then
        grep -m5 -E 'Font shape.*undefined|Missing character' "$WORK/test_icons.log"
        fail=1
    fi
    mv "$WORK/test_icons.pdf" "$WORK/test_icons-$eng.pdf"
done
exit $fail
