#!/bin/bash
set -euo pipefail

# install oh-my-zsh (non-interactive, no chsh, don't launch zsh, keep existing .zshrc)
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
export RUNZSH=no
export CHSH=no
export KEEP_ZSHRC=yes

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# ---------- 5) Copy config files ----------
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ ! -f "$script_dir/zshrc" ]]; then
  echo "[X] Missing $script_dir/zshrc next to setup.sh"; exit 3
fi
if [[ ! -f "$script_dir/x5.zsh-theme" ]]; then
  echo "[X] Missing $script_dir/x5.zsh-theme next to setup.sh"; exit 3
fi

# ensure themes dir exists
mkdir -p "$ZSH/themes"

# copy files
cp -f "$script_dir/zshrc" "$HOME/.zshrc"
cp -f "$script_dir/x5.zsh-theme" "$ZSH/themes/"

echo "[✓] Copied zshrc and theme files"

# (optional) print next step hint without executing zsh here:
echo "[i] Run 'exec zsh' or re-login to start zsh with the new config."

chsh -s $(which zsh)
