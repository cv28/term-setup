#!/usr/bin/env bash
set -euo pipefail

echo "=== tmux cross-platform bootstrap (macOS & Linux) ==="

# ---------- 1) Check & install dependencies ----------
if ! command -v tmux >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
  echo "[i] Missing dependencies, installing..."
  OS="$(uname -s)"

  if [[ "$OS" == "Darwin" ]]; then
    command -v brew >/dev/null 2>&1 || { echo "[X] Install Homebrew: https://brew.sh"; exit 1; }
    brew list tmux >/dev/null 2>&1 || brew install tmux
    brew list git  >/dev/null 2>&1 || brew install git
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y tmux git xclip wl-clipboard
  else
    echo "[X] Unsupported platform. Install tmux & git manually."
    exit 1
  fi
fi

command -v tmux >/dev/null 2>&1 || { echo "[X] tmux not found."; exit 1; }
command -v git  >/dev/null 2>&1 || { echo "[X] git not found."; exit 1; }
echo "[✓] tmux: $(tmux -V)"
echo "[✓] git:  $(git --version | awk '{print $3}')"

# ---------- 2) Install TPM ----------
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  echo "[i] Installing TPM → $TPM_DIR"
  mkdir -p "$HOME/.tmux/plugins"
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  echo "[i] TPM exists → updating"
  (cd "$TPM_DIR" && git pull --ff-only || true)
fi

# ---------- 3) Copy config ----------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC_CONF="$SCRIPT_DIR/tmux.conf"
DST_CONF="$HOME/.tmux.conf"
if [[ ! -f "$SRC_CONF" ]]; then
  echo "[X] Missing $SRC_CONF next to setup.sh"; exit 3
fi
cp -f "$SRC_CONF" "$DST_CONF"
echo "[✓] Wrote $DST_CONF"

# ---------- 4) Restart & source config ----------
tmux kill-server >/dev/null 2>&1 || true
tmux start-server
tmux source-file "$DST_CONF" || true
echo "[✓] tmux server started and config sourced"

# ---------- 5) Install plugins ----------
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

# ---------- 6) Self-check ----------
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