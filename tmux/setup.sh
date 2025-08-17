#!/usr/bin/env bash
set -euo pipefail

echo "=== tmux cross-platform bootstrap (macOS & Linux) ==="

# ---------- 0) Detect OS / package manager ----------
OS="$(uname -s)"
PKG=""
if [[ "$OS" == "Darwin" ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "[X] Homebrew not found on macOS. Install from https://brew.sh and re-run."
    exit 1
  fi
  PKG="brew"
else
  # Linux – detect a common package manager
  if command -v apt-get >/dev/null 2>&1; then PKG="apt";
  elif command -v dnf >/dev/null 2>&1; then PKG="dnf";
  elif command -v yum >/dev/null 2>&1; then PKG="yum";
  elif command -v pacman >/dev/null 2>&1; then PKG="pacman";
  elif command -v zypper >/dev/null 2>&1; then PKG="zypper";
  else
    echo "[!] Unknown package manager. Please install tmux & git manually, then re-run."
    PKG=""
  fi
fi
echo "[i] OS = $OS, pkgmgr = ${PKG:-unknown}"

# ---------- 1) Install dependencies (tmux, git, clipboard tools) ----------
install_pkg() {
  case "$PKG" in
    brew)
      brew list tmux >/dev/null 2>&1 || brew install tmux
      brew list git  >/dev/null 2>&1 || brew install git
      # macOS clipboard is native (pbcopy), no extra deps
      ;;
    apt)
      sudo apt-get update -y
      sudo apt-get install -y tmux git xclip wl-clipboard || true
      ;;
    dnf)
      sudo dnf install -y tmux git xclip wl-clipboard || true
      ;;
    yum)
      sudo yum install -y tmux git xclip || true
      # wl-clipboard may be unavailable on older yum repos
      ;;
    pacman)
      sudo pacman -Sy --needed --noconfirm tmux git xclip wl-clipboard || true
      ;;
    zypper)
      sudo zypper install -y tmux git xclip wl-clipboard || true
      ;;
    *)
      echo "[!] Skip auto-install; ensure 'tmux' and 'git' exist in PATH."
      ;;
  esac
}
install_pkg

# ---------- 2) Verify tmux & git ----------
command -v tmux >/dev/null 2>&1 || { echo "[X] tmux not found after install."; exit 2; }
command -v git  >/dev/null 2>&1 || { echo "[X] git not found after install."; exit 2; }
echo "[✓] tmux: $(tmux -V)"
echo "[✓] git:  $(git --version | awk '{print $3}')"

# ---------- 3) Install TPM ----------
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  echo "[i] Installing TPM → $TPM_DIR"
  mkdir -p "$HOME/.tmux/plugins"
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  echo "[i] TPM exists → updating"
  (cd "$TPM_DIR" && git pull --ff-only || true)
fi

# ---------- 4) Copy config from local folder ----------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC_CONF="$SCRIPT_DIR/tmux.conf"
DST_CONF="$HOME/.tmux.conf"
if [[ ! -f "$SRC_CONF" ]]; then
  echo "[X] Missing $SRC_CONF next to setup.sh"; exit 3
fi
cp -f "$SRC_CONF" "$DST_CONF"
echo "[✓] Wrote $DST_CONF"

# ---------- 5) Restart tmux server & source config ----------
tmux kill-server >/dev/null 2>&1 || true
tmux start-server
tmux source-file "$DST_CONF" || true
echo "[✓] tmux server started and config sourced"

# ---------- 6) Non-interactive plugin install via TPM ----------
# Use a separate named socket to avoid conflicts with user's live server.
SOCK_NAME="tpm$$"
SESSION="__tpm_install__"
echo "[i] Installing plugins (non-interactive)…"
tmux -L "$SOCK_NAME" start-server
tmux -L "$SOCK_NAME" new-session -d -s "$SESSION" -n "$SESSION"
tmux -L "$SOCK_NAME" run-shell "$TPM_DIR/bin/install_plugins"
tmux -L "$SOCK_NAME" run-shell "$TPM_DIR/bin/update_plugins all" || true
tmux -L "$SOCK_NAME" kill-session -t "$SESSION" || true
tmux -L "$SOCK_NAME" kill-server || true
echo "[✓] Plugins installed"

# ---------- 7) Minimal self-check ----------
tmux start-server
tmux source-file "$DST_CONF" || true
# Ensure server is running for config check
tmux new-session -d -s temp_check 2>/dev/null || true
PREFIX=$(tmux show -g prefix 2>/dev/null | awk '{print $2}')
MOUSE=$(tmux show -gw mouse 2>/dev/null | awk '{print $3}')
tmux kill-session -t temp_check 2>/dev/null || true
echo "---- Self-check ----"
echo "prefix = ${PREFIX:-N/A}    (expect: C-b)"
echo "mouse  = ${MOUSE:-N/A}     (expect: on)"
echo "plugins dir: $HOME/.tmux/plugins (expect: tpm, tmux-sensible, tmux-resurrect, tmux-continuum, tmux-yank)"
echo "---------------------"

echo "=== Done. Start tmux with: tmux ==="