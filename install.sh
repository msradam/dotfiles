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
        # Dangling symlink (target gone) — replace silently. Existing
        # valid symlinks are left untouched even if they point to a
        # different source, to avoid clobbering user-managed links.
        if [ ! -e "$dst" ]; then
            rm -f "$dst"
            mkdir -p "$(dirname "$dst")"
            ln -sf "$src" "$dst"
            ok "$dst → $src (replaced dangling symlink)"
        else
            warn "$dst already linked"
        fi
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

# ── First-flight: Xcode CLT + Homebrew ───────────────────────────
# On a fresh machine neither exists. Install before anything else
# touches `brew`. Both commands are idempotent / no-op when present.
if ! xcode-select -p &>/dev/null; then
    info "installing Xcode Command Line Tools (a GUI prompt will appear)..."
    xcode-select --install || true
    warn "re-run this script once the CLT install finishes"
    exit 0
fi

if ! command -v brew &>/dev/null; then
    info "installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # shellcheck disable=SC2016
    eval "$(/opt/homebrew/bin/brew shellenv)"
    ok "Homebrew installed"
fi

# ── Homebrew bundle (formulae, casks, fonts) ─────────────────────
# Brewfile tracks everything installed. `brew bundle install` is
# idempotent: anything already present is skipped automatically.
info "syncing Brewfile (skips already-installed)..."
if [ -f "$DOTFILES/Brewfile" ]; then
    # Don't abort the whole installer on partial Brewfile failures
    # (e.g. uv-tool conflicts with pre-existing pip --user binaries).
    # Symlinks and downstream steps must still run.
    if brew bundle install --file="$DOTFILES/Brewfile" --no-upgrade; then
        ok "Brewfile synced"
    else
        warn "Brewfile sync had failures — review output above, continuing"
    fi
else
    warn "no Brewfile found at $DOTFILES/Brewfile"
fi

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

# ── Rosé Pine for bat (main + dawn) ────────────────────────────
# Upstream lives at rose-pine/tm-theme/dist. _palette_switch in
# .zshrc swaps BAT_THEME between "Rose Pine" and "Rose Pine Dawn"
# based on macOS appearance, so both files need to be present.
if command -v bat &>/dev/null; then
    info "setting up bat themes..."
    BAT_THEMES="$(bat --config-dir)/themes"
    mkdir -p "$BAT_THEMES"
    fetched=0
    _fetch_theme() {
        local name="$1" remote="$2"
        local dst="$BAT_THEMES/$name.tmTheme"
        [ -f "$dst" ] && return 0
        if curl -fsSL -o "$dst" \
            "https://raw.githubusercontent.com/rose-pine/tm-theme/main/dist/$remote"; then
            ok "  $name fetched"
            fetched=1
        else
            rm -f "$dst"
            warn "  $name fetch failed — continuing"
        fi
    }
    _fetch_theme "Rose Pine"      "rose-pine.tmTheme"
    _fetch_theme "Rose Pine Dawn" "rose-pine-dawn.tmTheme"
    if [ "$fetched" -eq 1 ]; then
        bat cache --build >/dev/null
    fi
else
    warn "bat not on PATH — skipping bat theme setup"
fi

# ── Rosé Pine for zsh-syntax-highlighting ─────────────────────
# Two palettes; .zshrc precmd hook picks the right one based on the
# macOS appearance, mirroring the Starship dawn/main split.
info "setting up zsh-syntax-highlighting themes..."
mkdir -p "$HOME/.zsh"
# Clean up the pre-split symlink if it survives from an older install.
[ -L "$HOME/.zsh/rose-pine-zsh-syntax-highlighting.zsh" ] && \
    rm -f "$HOME/.zsh/rose-pine-zsh-syntax-highlighting.zsh"
link "$DOTFILES/zsh/rose-pine-zsh-syntax-highlighting-main.zsh" "$HOME/.zsh/rose-pine-zsh-syntax-highlighting-main.zsh"
link "$DOTFILES/zsh/rose-pine-zsh-syntax-highlighting-dawn.zsh" "$HOME/.zsh/rose-pine-zsh-syntax-highlighting-dawn.zsh"

# ── Symlinks ─────────────────────────────────────────────────────
info "linking configs..."

link "$DOTFILES/zsh/.zshrc"              "$HOME/.zshrc"
link "$DOTFILES/zsh/.zprofile"           "$HOME/.zprofile"
link "$DOTFILES/starship/starship-dawn.toml"   "$HOME/.config/starship-dawn.toml"
link "$DOTFILES/starship/starship-main.toml"   "$HOME/.config/starship-main.toml"
link "$DOTFILES/ghostty/config"          "$HOME/.config/ghostty/config"
link "$DOTFILES/yabai/yabairc"           "$HOME/.config/yabai/yabairc"
link "$DOTFILES/git/.gitconfig"          "$HOME/.gitconfig"
link "$DOTFILES/bob/settings.json"       "$HOME/Library/Application Support/IBM Bob/User/settings.json"

# ── Bob (VS Code fork) extensions ────────────────────────────────
# Bob ships `bobide` as its CLI. It may not be on PATH until the
# user runs "Shell Command: Install 'bobide' command in PATH" from
# inside the app, so fall back to the absolute path inside the bundle.
BOBIDE_BIN="$(command -v bobide || true)"
[ -z "$BOBIDE_BIN" ] && BOBIDE_BIN="/Applications/IBM Bob.app/Contents/Resources/app/bin/bobide"

bob_install_extensions() {
    info "installing Bob extensions..."
    local failed=0
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue   # skip comments
        [[ -z "${line// }" ]] && continue              # skip blanks
        local ext="${line%%#*}"                        # strip inline comment
        ext="${ext// /}"
        [[ -z "$ext" ]] && continue
        if "$BOBIDE_BIN" --install-extension "$ext" --force &>/dev/null; then
            ok "  $ext"
        else
            warn "  $ext (failed — skipped)"
            (( failed++ )) || true
        fi
    done < "$DOTFILES/bob/extensions.txt"
    # NB: bare `[ -gt 0 ] && warn` returns non-zero when failed=0,
    # which trips `set -e` on the function call. Use an explicit `if`.
    if [ "$failed" -gt 0 ]; then
        warn "Bob: $failed extension(s) failed to install"
    fi
}

if [ -x "$BOBIDE_BIN" ]; then
    info "Bob detected: $BOBIDE_BIN"
    bob_install_extensions
else
    warn "bobide CLI not found — install IBM Bob first, then re-run"
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

# ── npm global packages ──────────────────────────────────────────
# Syncs CLI tools installed globally via npm (e.g. bobshell).
# Requires a Node version active via fnm.
if command -v npm &>/dev/null && [ -f "$DOTFILES/npm/globals.txt" ]; then
    info "syncing global npm packages..."
    installed="$(npm ls -g --depth=0 --parseable 2>/dev/null | xargs -n1 basename 2>/dev/null || true)"
    while IFS= read -r pkg; do
        [[ "$pkg" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${pkg// }" ]] && continue
        pkg="${pkg%%#*}"; pkg="${pkg// /}"
        [[ -z "$pkg" ]] && continue
        if echo "$installed" | grep -qx "$pkg"; then
            warn "  $pkg already installed"
        else
            info "  installing $pkg..."
            npm install -g "$pkg" 2>&1 | tail -1 || warn "  $pkg (failed)"
        fi
    done < "$DOTFILES/npm/globals.txt"
elif ! command -v npm &>/dev/null; then
    warn "npm not on PATH — run \`fnm install --lts && fnm default lts-latest\` first, then re-run"
fi

# ── macOS app defaults ───────────────────────────────────────────
# Disable macOS Resume for Ghostty so new launches don't restore the
# previous working directory / surfaces. Ghostty's own
# window-save-state=never is overridden by this NSGlobal flag.
info "applying macOS app defaults..."
defaults write com.mitchellh.ghostty NSQuitAlwaysKeepsWindows -bool false
ok "Ghostty: macOS Resume disabled"

# ── Start services ───────────────────────────────────────────────
info "starting services..."
yabai --restart-service 2>/dev/null || true

echo ""
ok "done! restart your terminal or run: source ~/.zshrc"
echo ""
