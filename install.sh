#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

info()  { echo -e "${BLUE}[info]${NC}  $1"; }
ok()    { echo -e "${GREEN}[ok]${NC}    $1"; }
warn()  { echo -e "${YELLOW}[skip]${NC}  $1"; }

link() {
    local src="$1" dst="$2"
    if [ -L "$dst" ]; then
        warn "$dst already linked"
    elif [ -e "$dst" ]; then
        mv "$dst" "${dst}.backup"
        info "backed up $dst → ${dst}.backup"
        ln -sf "$src" "$dst"
        ok "$dst → $src"
    else
        mkdir -p "$(dirname "$dst")"
        ln -sf "$src" "$dst"
        ok "$dst → $src"
    fi
}

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║       dotfiles install script        ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ── Homebrew dependencies ────────────────────────────────────────
info "checking brew dependencies..."
DEPS=(starship fzf zoxide eza bat zsh-autosuggestions zsh-syntax-highlighting zsh-completions)
for dep in "${DEPS[@]}"; do
    if ! brew list "$dep" &>/dev/null; then
        info "installing $dep..."
        brew install "$dep"
    fi
done

if ! brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
    info "installing JetBrains Mono Nerd Font..."
    brew install --cask font-jetbrains-mono-nerd-font
fi

# ── Catppuccin for bat ─────────────────────────────────────────
info "setting up bat theme..."
BAT_THEMES="$(bat --config-dir)/themes"
mkdir -p "$BAT_THEMES"
if [ ! -f "$BAT_THEMES/Catppuccin Mocha.tmTheme" ]; then
    curl -fsSL -o "$BAT_THEMES/Catppuccin Mocha.tmTheme" \
        "https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme"
    bat cache --build
    ok "bat catppuccin theme installed"
fi

# ── Catppuccin for zsh-syntax-highlighting ────────────────────
info "setting up zsh-syntax-highlighting theme..."
mkdir -p "$HOME/.zsh"
link "$DOTFILES/zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh" "$HOME/.zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh"

# ── Symlinks ─────────────────────────────────────────────────────
info "linking configs..."

link "$DOTFILES/zsh/.zshrc"              "$HOME/.zshrc"
link "$DOTFILES/zsh/.zprofile"           "$HOME/.zprofile"
link "$DOTFILES/starship/starship.toml"  "$HOME/.config/starship.toml"
link "$DOTFILES/kitty/kitty.conf"        "$HOME/.config/kitty/kitty.conf"
link "$DOTFILES/yabai/yabairc"           "$HOME/.config/yabai/yabairc"
link "$DOTFILES/git/.gitconfig"          "$HOME/.gitconfig"
link "$DOTFILES/vscode/settings.json"    "$HOME/Library/Application Support/Code/User/settings.json"

# ── Start services ───────────────────────────────────────────────
info "starting services..."
yabai --restart-service 2>/dev/null || true

echo ""
ok "done! restart your terminal or run: source ~/.zshrc"
echo ""
