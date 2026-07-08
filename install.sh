#!/usr/bin/env bash
#
# deepclaude installer.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/RafiulM/deepclaude/main/install.sh | bash
#
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/RafiulM/deepclaude/main"
REPO_CDN="https://cdn.jsdelivr.net/gh/RafiulM/deepclaude@main"
CMD_NAME="deepclaude"
BIN_DIR="${DEEPCLAUDE_BIN_DIR:-$HOME/.local/bin}"

mkdir -p "$BIN_DIR"

# Download a file to $2, trying each base URL in order. Retries each URL a
# few times with backoff before falling through — GitHub's raw.githubusercontent.com
# frequently returns 429 on shared/corporate IPs, so a CDN mirror is used as
# a fallback.
fetch() {
  local path="$1" out="$2" base url ok
  for base in "$REPO_RAW" "$REPO_CDN"; do
    url="$base/$path"
    ok=0
    if command -v curl >/dev/null 2>&1; then
      if curl -fsSL --retry 3 --retry-delay 2 --retry-all-errors "$url" -o "$out"; then
        ok=1
      fi
    elif command -v wget >/dev/null 2>&1; then
      if wget -q --tries=3 --waitretry=2 -O "$out" "$url"; then
        ok=1
      fi
    else
      echo "Need curl or wget." >&2
      exit 1
    fi
    if [ "$ok" -eq 1 ]; then
      return 0
    fi
    echo "Download from $base failed (rate limited or unreachable), trying next mirror..." >&2
  done
  echo "Failed to download $path from all mirrors." >&2
  exit 1
}

echo "Installing $CMD_NAME to $BIN_DIR ..."
fetch "$CMD_NAME" "$BIN_DIR/$CMD_NAME"
chmod +x "$BIN_DIR/$CMD_NAME"

echo "Installed: $BIN_DIR/$CMD_NAME"

case ":$PATH:" in
  *":$BIN_DIR:"*)
    echo "Ready. Run: $CMD_NAME"
    ;;
  *)
    echo
    echo "NOTE: $BIN_DIR is not on your PATH."
    echo "Add this to your shell profile (~/.bashrc or ~/.zshrc):"
    echo "  export PATH=\"$BIN_DIR:\$PATH\""
    echo "Then open a new terminal and run: $CMD_NAME"
    ;;
esac
