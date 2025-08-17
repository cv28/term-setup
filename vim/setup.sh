#!/bin/bash
set -euo pipefail

echo "=== vim setup ==="

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Install Vundle if not exists
if [[ ! -d ~/.vim/bundle/Vundle.vim ]]; then
    echo "[i] Installing Vundle..."
    mkdir -p ~/.vim/bundle
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    echo "[✓] Vundle installed"
else
    echo "[i] Vundle already exists"
fi

# Copy vimrc
if [[ ! -f "$script_dir/vimrc" ]]; then
    echo "[X] Missing $script_dir/vimrc next to setup.sh"
    exit 3
fi
cp "$script_dir/vimrc" "$HOME/.vimrc"
echo "[✓] Copied .vimrc"

# Install plugins non-interactively
echo "[i] Installing vim plugins..."
vim -E -s -u "$HOME/.vimrc" +PluginInstall +qall >/dev/null 2>&1 || true
echo "[✓] Vim plugins installed"

echo "[✓] vim setup complete"
