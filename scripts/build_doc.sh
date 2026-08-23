#!/usr/bin/env bash
# Build the package documentation PDF (LuaLaTeX) against the uninstalled tree.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
P="$ROOT/phosphoricons"

export TEXINPUTS="$P/tex//:"
export TFMFONTS="$P/tfm//:"
export ENCFONTS="$P/enc//:"
export TTFONTS="$P/truetype//:"
export TEXFONTMAPS="$P/map//:"

cd "$P/doc"
for run in 1 2; do
    lualatex -interaction=nonstopmode -halt-on-error phosphoricons.tex \
        > /dev/null || { grep -A3 '^!' phosphoricons.log | head -20; exit 1; }
done
rm -f phosphoricons.aux phosphoricons.log phosphoricons.out
echo "built $P/doc/phosphoricons.pdf"
