#!/usr/bin/env bash
# Full upgrade pipeline: fetch the latest @phosphor-icons/web release,
# regenerate all binding artefacts, bump version strings, compile-test every
# icon on pdfLaTeX/XeLaTeX/LuaLaTeX and rebuild the documentation.
#
# Usage: upgrade_phosphor.sh [upstream-version]
# Requires: python3 with fontTools, otftotfm, a TeX Live with all three engines.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PY="python3"
[ -x "$ROOT/.venv/bin/python" ] && PY="$ROOT/.venv/bin/python"

scripts/fetch_upstream.sh "${1:-}"
VERSION=$($PY -c "import json; print(json.load(open('build/upstream/package/package.json'))['version'])")
OLD_VERSION=$(sed -nE 's/.*ProvidesExplPackage\{phosphoricons\}\{[^}]*\}\{([0-9.]+)-[0-9]+\}.*/\1/p' \
    phosphoricons/tex/phosphoricons.sty)

if [ "$VERSION" = "$OLD_VERSION" ] && [ "${FORCE:-0}" != 1 ]; then
    echo "already at @phosphor-icons/web $VERSION - nothing to do (FORCE=1 to regenerate)"
    [ -n "${GITHUB_OUTPUT:-}" ] && echo "updated=false" >> "$GITHUB_OUTPUT"
    exit 0
fi

echo "upgrading $OLD_VERSION -> $VERSION"
$PY scripts/generate_binding.py

DATE=$(date +%Y/%m/%d)
PKGVERSION="$VERSION-1"
for f in phosphoricons/tex/phosphoricons.sty \
         phosphoricons/tex/phosphoricons-generic-helper.sty \
         phosphoricons/tex/phosphoricons-utex-helper.sty; do
    sed -i.bak -E \
        "s|(ProvidesExplPackage\{phosphoricons[a-z-]*\})\{[0-9/]+\}\{[0-9.-]+\}|\1{$DATE}{$PKGVERSION}|" \
        "$f" && rm "$f.bak"
done
sed -i.bak -E "s|(\\\\newcommand\\\\ppversion\{)[0-9.-]+(\})|\1$PKGVERSION\2|" \
    phosphoricons/doc/phosphoricons.tex && rm phosphoricons/doc/phosphoricons.tex.bak

scripts/test_icons.sh
scripts/build_doc.sh

echo "upgrade to $PKGVERSION complete"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
    {
        echo "updated=true"
        echo "version=$VERSION"
        echo "pkgversion=$PKGVERSION"
    } >> "$GITHUB_OUTPUT"
fi
