#!/bin/bash
set -euo pipefail

# Self-contained terminal setup installer
# Downloads all necessary files from GitHub and runs the complete setup

REPO_URL="https://raw.githubusercontent.com/cv28/term-setup/main"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "=== Terminal Setup Installer ==="
echo "Downloading configuration files..."

# Create directory structure
mkdir -p "$TEMP_DIR"/{tmux,vim,zsh}

# Download all configuration files
echo "Downloading tmux files..."
curl -fsSL "$REPO_URL/tmux/setup.sh" -o "$TEMP_DIR/tmux/setup.sh"
curl -fsSL "$REPO_URL/tmux/tmux.conf" -o "$TEMP_DIR/tmux/tmux.conf"

echo "Downloading vim files..."
curl -fsSL "$REPO_URL/vim/setup.sh" -o "$TEMP_DIR/vim/setup.sh"
curl -fsSL "$REPO_URL/vim/vimrc" -o "$TEMP_DIR/vim/vimrc"

echo "Downloading zsh files..."
curl -fsSL "$REPO_URL/zsh/setup.sh" -o "$TEMP_DIR/zsh/setup.sh"
curl -fsSL "$REPO_URL/zsh/zshrc" -o "$TEMP_DIR/zsh/zshrc"
curl -fsSL "$REPO_URL/zsh/x5.zsh-theme" -o "$TEMP_DIR/zsh/x5.zsh-theme"

echo "All files downloaded. Starting setup..."

# Run each setup script
for component in tmux vim zsh; do
    echo "Setting up $component..."
    cd "$TEMP_DIR/$component"
    chmod +x setup.sh
    if bash setup.sh; then
        echo "✓ $component setup completed successfully"
    else
        echo "⚠ Warning: $component setup had issues but continuing..."
    fi
done

echo "=== All setups completed! ==="
echo "Restart your terminal or run 'source ~/.zshrc' to apply changes."
