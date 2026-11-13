#!/usr/bin/env bash
# Build T3 Code from this checkout and place the runnable app at the repo root.
# Usage: ./build-app.sh            (full build, then unpack)
#        ./build-app.sh --unpack   (skip the build, unpack the newest release/*.zip)
set -euo pipefail

cd "$(dirname "$0")"
export PATH="$HOME/.cargo/bin:$PWD/node_modules/.bin:$PATH"

APP_NAME="T3 Code (Beta).app"

if [[ "${1:-}" != "--unpack" ]]; then
  vp run dist:desktop:dmg
fi

ZIP="$(ls -t release/T3-Code-*-arm64.zip 2>/dev/null | head -1 || true)"
if [[ -z "$ZIP" ]]; then
  echo "No release/T3-Code-*-arm64.zip found. Run without --unpack first." >&2
  exit 1
fi

if ps -axo comm | grep -qF "$APP_NAME/Contents/MacOS/"; then
  echo "T3 Code (Beta) is running. Quit it (Cmd+Q) and run this script again." >&2
  exit 1
fi

rm -rf "./$APP_NAME"
# ditto keeps the bundle's symlinks and resource forks, which unzip can drop.
ditto -x -k "$ZIP" .
xattr -dr com.apple.quarantine "./$APP_NAME" 2>/dev/null || true

echo
echo "App ready: $PWD/$APP_NAME"
echo "Open it with:  open \"$PWD/$APP_NAME\""
