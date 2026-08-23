#!/usr/bin/env bash
# Download and unpack @phosphor-icons/web into build/upstream/package.
# Usage: fetch_upstream.sh [version]   (default: latest from the npm registry)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/build/upstream"

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    VERSION=$(curl -sf https://registry.npmjs.org/@phosphor-icons/web \
        | python3 -c "import json,sys; print(json.load(sys.stdin)['dist-tags']['latest'])")
fi

echo "fetching @phosphor-icons/web@$VERSION"
rm -rf "$DEST"
mkdir -p "$DEST"
curl -sfL "https://registry.npmjs.org/@phosphor-icons/web/-/web-$VERSION.tgz" \
    | tar xz -C "$DEST"
echo "unpacked to $DEST/package"
