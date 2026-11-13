#!/usr/bin/env bash
# Run T3 Code desktop in dev mode (hot reload, no build) against the same data as the built app.
# Stays attached to this terminal; Ctrl+C stops server, Vite and Electron together.
set -euo pipefail

cd "$(dirname "$0")"
export PATH="$HOME/.cargo/bin:$PWD/node_modules/.bin:$PATH"

APP_NAME="T3 Code (Beta).app"

# Dev and the built app share ~/.t3/userdata, so only one may run at a time.
if ps -axo comm | grep -F "$APP_NAME/Contents/MacOS/" >/dev/null; then
  echo "T3 Code (Beta) is running. Quit it (Cmd+Q) before starting dev mode." >&2
  exit 1
fi

exec vp run dev:desktop "$@"
