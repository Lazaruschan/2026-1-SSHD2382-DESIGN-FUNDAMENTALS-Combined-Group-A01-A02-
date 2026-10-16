#!/usr/bin/env bash
# Export SSHD2382 lecture decks to self-contained HTML (see export-slides.py).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
PYTHON="python3"
if ! command -v python3 >/dev/null 2>&1; then
  PYTHON="python"
fi

if ! command -v node >/dev/null 2>&1; then
  if [[ -d "$HOME/.nvm/versions/node" ]]; then
    LATEST_NODE="$(ls "$HOME/.nvm/versions/node" | sort -V | tail -1)"
    export PATH="$HOME/.nvm/versions/node/$LATEST_NODE/bin:$PATH"
  fi
fi

exec "$PYTHON" "$ROOT/export-slides.py"
