#!/usr/bin/env bash
# Install the package into the user's texmf tree (TDS layout) and register
# the font map.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
P="$ROOT/phosphoricons"
TEXMF="$(kpsewhich -var-value TEXMFHOME)"

install -d "$TEXMF/tex/latex/phosphoricons" \
           "$TEXMF/fonts/truetype/public/phosphoricons" \
           "$TEXMF/fonts/tfm/public/phosphoricons" \
           "$TEXMF/fonts/enc/dvips/phosphoricons" \
           "$TEXMF/fonts/map/dvips/phosphoricons" \
           "$TEXMF/doc/fonts/phosphoricons"

cp "$P"/tex/*      "$TEXMF/tex/latex/phosphoricons/"
cp "$P"/truetype/* "$TEXMF/fonts/truetype/public/phosphoricons/"
cp "$P"/tfm/*      "$TEXMF/fonts/tfm/public/phosphoricons/"
cp "$P"/enc/*      "$TEXMF/fonts/enc/dvips/phosphoricons/"
cp "$P"/map/*      "$TEXMF/fonts/map/dvips/phosphoricons/"
[ -f "$P/doc/phosphoricons.pdf" ] && cp "$P"/doc/* "$TEXMF/doc/fonts/phosphoricons/"

mktexlsr "$TEXMF"
updmap-user --enable Map=phosphoricons.map
echo "installed into $TEXMF"
