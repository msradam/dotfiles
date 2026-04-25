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
DEPS=(starship fzf zoxide eza bat zsh-autosuggestions zsh-syntax-highlighting zsh-completions fnm)
for dep in "${DEPS[@]}"; do
    if ! brew list "$dep" &>/dev/null; then
        info "installing $dep..."
        brew install "$dep"
    fi
done

# ── Fonts ─────────────────────────────────────────────────────────
info "installing fonts..."

# Install fonts via Homebrew (recommended: auto-updated)
FONT_CASKS=(
    "font-jetbrains-mono-nerd-font"
    "font-cascadia-mono"
    "font-fira-code-nerd-font"
    "font-geist-mono-nerd-font"
    "font-gohufont-nerd-font"
    "font-iosevka-nerd-font"
)
for cask in "${FONT_CASKS[@]}"; do
    if ! brew list --cask "$cask" &>/dev/null 2>&1; then
        info "  installing $cask..."
        brew install --cask "$cask" 2>/dev/null || warn "  $cask (failed)"
    fi
done
ok "Homebrew fonts installed"

# Also copy any .ttf files from dotfiles/fonts directory (local overrides)
FONT_SRC="$DOTFILES/fonts"
FONT_DST="$HOME/Library/Fonts"
mkdir -p "$FONT_DST"
if [ -d "$FONT_SRC" ]; then
    count=0
    for font in "$FONT_SRC"/*.ttf; do
        if [ -f "$font" ]; then
            cp "$font" "$FONT_DST/" && (( count++ )) || true
        fi
    done
    if [ "$count" -gt 0 ]; then
        ok "copied $count local fonts"
    fi
else
    warn "fonts directory not found"
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
link "$DOTFILES/kitty/keybindings.conf"  "$HOME/.config/kitty/keybindings.conf"
link "$DOTFILES/kitty/shortcuts.sh"      "$HOME/.config/kitty/shortcuts.sh"
link "$DOTFILES/yabai/yabairc"           "$HOME/.config/yabai/yabairc"
link "$DOTFILES/git/.gitconfig"          "$HOME/.gitconfig"
link "$DOTFILES/vscode/settings.json"    "$HOME/Library/Application Support/Code/User/settings.json"

# ── VS Code extensions ────────────────────────────────────────────

vscode_install_extensions() {
    local cli="$1" label="$2"
    info "installing extensions for $label..."
    local failed=0
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue   # skip comments
        [[ -z "${line// }" ]] && continue              # skip blanks
        local ext="${line%%#*}"                        # strip inline comment
        ext="${ext// /}"
        [[ -z "$ext" ]] && continue
        if "$cli" --install-extension "$ext" --force &>/dev/null; then
            ok "  $ext"
        else
            warn "  $ext (failed — skipped)"
            (( failed++ )) || true
        fi
    done < "$DOTFILES/vscode/extensions.txt"
    [ "$failed" -gt 0 ] && warn "$label: $failed extension(s) failed to install"
}

if command -v code &>/dev/null; then
    info "VS Code detected"
    vscode_install_extensions code "VS Code"
else
    warn "VS Code CLI (code) not found — skipping VS Code extensions"
fi

# ── Firefox userChrome ───────────────────────────────────────────
info "setting up Firefox userChrome..."
FIREFOX_DIR="$HOME/Library/Application Support/Firefox"
PROFILES_INI="$FIREFOX_DIR/profiles.ini"

if [ ! -f "$PROFILES_INI" ]; then
    warn "Firefox profiles.ini not found — skipping"
else
    _install_ff_profile() {
        local path="$1" is_rel="$2"
        [[ -z "$path" ]] && return
        local full_path
        [[ "$is_rel" == "1" ]] && full_path="$FIREFOX_DIR/$path" || full_path="$path"
        [[ ! -d "$full_path" ]] && return
        mkdir -p "$full_path/chrome"
        link "$DOTFILES/firefox/userChrome.css" "$full_path/chrome/userChrome.css"
        local user_js="$full_path/user.js"
        local pref='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
        if grep -q "legacyUserProfileCustomizations" "$user_js" 2>/dev/null; then
            sed -i '' "s|.*legacyUserProfileCustomizations.*|$pref|" "$user_js"
        else
            echo "$pref" >> "$user_js"
        fi
        ok "Firefox: $(basename "$full_path")"
    }

    is_relative="" profile_path=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^\[.*\]$ ]]; then
            _install_ff_profile "$profile_path" "$is_relative"
            is_relative="" profile_path=""
        elif [[ "$line" =~ ^IsRelative=(.+)$ ]]; then is_relative="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^Path=(.+)$ ]];       then profile_path="${BASH_REMATCH[1]}"
        fi
    done < "$PROFILES_INI"
    _install_ff_profile "$profile_path" "$is_relative"  # flush last section
fi

# ── Start services ───────────────────────────────────────────────
info "starting services..."
yabai --restart-service 2>/dev/null || true

echo ""
ok "done! restart your terminal or run: source ~/.zshrc"
echo ""
