#!/usr/bin/env bash
# mkm4b installer — copies the script to a directory on your PATH

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="$SCRIPT_DIR/mkm4b"
DEST="${1:-/usr/local/bin}"

# ── colours (no-op if not a terminal) ────────────────────────────────────────
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; NC=''
fi

ok()   { echo -e "${GREEN}✓${NC}  $*"; }
warn() { echo -e "${YELLOW}⚠${NC}   $*"; }
die()  { echo -e "${RED}✗${NC}  $*" >&2; exit 1; }

# ── sanity checks ─────────────────────────────────────────────────────────────
[[ -f "$BINARY" ]] || die "Cannot find mkm4b in $SCRIPT_DIR — run this from the cloned repo."
[[ -x "$BINARY" ]] || chmod +x "$BINARY"

# ── install ───────────────────────────────────────────────────────────────────
install_binary() {
  if [[ -w "$DEST" ]]; then
    cp "$BINARY" "$DEST/mkm4b"
  elif command -v sudo >/dev/null 2>&1; then
    echo "  → $DEST requires sudo:"
    sudo cp "$BINARY" "$DEST/mkm4b"
    sudo chmod +x "$DEST/mkm4b"
  else
    die "Cannot write to $DEST and sudo is not available.\nTry: ./install.sh ~/bin"
  fi
}

echo ""
echo "  mkm4b installer"
echo "  ──────────────────────────────────────"

# Create dest dir if it doesn't exist (e.g. ~/bin)
if [[ ! -d "$DEST" ]]; then
  warn "$DEST does not exist — creating it"
  mkdir -p "$DEST"
fi

echo "  Installing to $DEST/mkm4b ..."
install_binary
ok "Installed: $DEST/mkm4b"

# ── PATH check ────────────────────────────────────────────────────────────────
if ! echo ":$PATH:" | grep -q ":$DEST:"; then
  warn "$DEST is not in your PATH."
  echo ""
  echo "  Add this to your shell config (~/.zshrc or ~/.bashrc):"
  echo ""
  echo "      export PATH=\"$DEST:\$PATH\""
  echo ""
  echo "  Then reload it:"
  echo "      source ~/.zshrc   # or: source ~/.bashrc"
  echo ""
fi

# ── dep check ─────────────────────────────────────────────────────────────────
echo ""
echo "  Checking dependencies..."
MISSING=0

_check() {
  local cmd="$1" brew_pkg="$2" apt_pkg="$3"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd"
  else
    warn "$cmd not found"
    if [[ "$(uname -s)" == "Darwin" ]]; then
      echo "       → brew install $brew_pkg"
    else
      echo "       → sudo apt install $apt_pkg"
      echo "         (or: sudo dnf install $apt_pkg)"
    fi
    MISSING=1
  fi
}

if [[ "$(uname -s)" == "Darwin" ]]; then
  _check grealpath coreutils coreutils
  _check gsort     coreutils coreutils
else
  _check realpath  coreutils coreutils
  _check sort      coreutils coreutils
fi

_check ffmpeg  ffmpeg ffmpeg
_check ffprobe ffmpeg ffmpeg

echo ""
if (( MISSING )); then
  warn "Install missing dependencies above, then mkm4b is ready to use."
else
  ok "All dependencies satisfied."
  echo ""
  echo "  Try it:"
  echo "      mkm4b --version"
  echo "      mkm4b /path/to/your/recordings/"
fi
echo ""
