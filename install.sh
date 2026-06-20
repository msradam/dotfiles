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

HEADLESS=false
[[ "${1:-}" == "--headless" ]] && HEADLESS=true

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║       dotfiles install script        ║"
echo "  ╚══════════════════════════════════════╝"
echo ""
$HEADLESS && info "headless mode enabled"

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

# ── Migrations: uninstall superseded tools ───────────────────────
# Idempotent — each step is a no-op when the target is already gone.
# Converges a re-run (or a machine mid-migration) on the current
# stack: zimfw (not OMZ), Zed (not Bob/VS Code), Catppuccin themes.

# Oh My Zsh → zimfw (<10ms startup vs OMZ's 200-400ms)
if [ -d "$HOME/.oh-my-zsh" ]; then
    info "removing Oh My Zsh (replaced by zimfw)..."
    rm -rf "$HOME/.oh-my-zsh"
    rm -f "$HOME/.zshrc.pre-oh-my-zsh"
    ok "Oh My Zsh removed"
fi

# brew-managed zsh plugins → zimfw modules
for pkg in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
    if brew list "$pkg" &>/dev/null 2>&1; then
        info "removing $pkg from brew (now a zimfw module)..."
        brew uninstall --ignore-dependencies "$pkg" && ok "$pkg removed"
    fi
done

# IBM Bob + VS Code → Zed
for app in "IBM Bob" "Visual Studio Code"; do
    if [ -d "/Applications/$app.app" ]; then
        osascript -e "quit app \"$app\"" 2>/dev/null || true
        rm -rf "/Applications/$app.app" && ok "removed $app.app (replaced by Zed)"
    fi
done
rm -rf "$HOME/Library/Application Support/IBM Bob" "$HOME/.bob" \
       "$HOME/Library/Application Support/Code" "$HOME/.vscode" 2>/dev/null || true

# bobshell npm global → no longer used
if command -v npm &>/dev/null && npm ls -g --depth=0 bobshell &>/dev/null; then
    npm uninstall -g bobshell &>/dev/null && ok "uninstalled bobshell npm global"
fi

# Stale Rosé Pine assets → replaced by Catppuccin
rm -f "$HOME/.config/starship-main.toml" "$HOME/.config/starship-dawn.toml" \
      "$HOME/.zsh/rose-pine-zsh-syntax-highlighting-main.zsh" \
      "$HOME/.zsh/rose-pine-zsh-syntax-highlighting-dawn.zsh" 2>/dev/null || true
if command -v bat &>/dev/null; then
    _stale_bat="$(bat --config-dir)/themes"
    rm -f "$_stale_bat/Rose Pine.tmTheme" "$_stale_bat/Rose Pine Dawn.tmTheme" 2>/dev/null || true
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

# ── zimfw ────────────────────────────────────────────────────────
# Modules are defined in ~/.zimrc (symlinked below). The .zshrc
# self-bootstraps on first open, but we pre-fetch here so the shell
# is fully configured immediately after install.
ZIM_HOME="$HOME/.zim"
if [ ! -f "$ZIM_HOME/zimfw.zsh" ]; then
    info "installing zimfw..."
    mkdir -p "$ZIM_HOME"
    if curl -fsSL -o "$ZIM_HOME/zimfw.zsh" \
            https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh; then
        ok "zimfw downloaded"
    else
        warn "zimfw download failed — shell plugins will install on first shell open"
    fi
else
    ok "zimfw already present"
fi

# ── Python 3.12 via uv ───────────────────────────────────────────
# uv replaces pyenv + pip + venv + pipx in a single binary.
# `uv python install` downloads pre-built CPython (seconds, not minutes).
if command -v uv &>/dev/null; then
    if ! uv python list 2>/dev/null | grep -q "3\.12"; then
        info "installing Python 3.12 via uv..."
        uv python install 3.12 2>&1 | tail -3 || warn "uv python install had errors"
        ok "Python 3.12 installed"
    else
        ok "Python 3.12 already installed"
    fi
fi

# ── Catppuccin for bat (latte + mocha) ─────────────────────────
# Upstream lives at catppuccin/bat/themes. _palette_switch in .zshrc
# swaps BAT_THEME between "Catppuccin Latte" and "Catppuccin Mocha"
# based on macOS appearance, so both files need to be present.
if command -v bat &>/dev/null; then
    info "setting up bat themes..."
    BAT_THEMES="$(bat --config-dir)/themes"
    mkdir -p "$BAT_THEMES"
    fetched=0
    _fetch_theme() {
        local name="$1"
        local dst="$BAT_THEMES/$name.tmTheme"
        [ -f "$dst" ] && return 0
        if curl -fsSL -o "$dst" \
            "https://raw.githubusercontent.com/catppuccin/bat/main/themes/${name// /%20}.tmTheme"; then
            ok "  $name fetched"
            fetched=1
        else
            rm -f "$dst"
            warn "  $name fetch failed — continuing"
        fi
    }
    _fetch_theme "Catppuccin Latte"
    _fetch_theme "Catppuccin Mocha"
    if [ "$fetched" -eq 1 ]; then
        bat cache --build >/dev/null
    fi
else
    warn "bat not on PATH — skipping bat theme setup"
fi

# ── Catppuccin for zsh-syntax-highlighting ─────────────────────
# Two palettes; .zshrc precmd hook picks the right one based on the
# macOS appearance, mirroring the Starship latte/mocha split.
info "setting up zsh-syntax-highlighting themes..."
mkdir -p "$HOME/.zsh"
link "$DOTFILES/zsh/catppuccin-zsh-syntax-highlighting-mocha.zsh" "$HOME/.zsh/catppuccin-zsh-syntax-highlighting-mocha.zsh"
link "$DOTFILES/zsh/catppuccin-zsh-syntax-highlighting-latte.zsh" "$HOME/.zsh/catppuccin-zsh-syntax-highlighting-latte.zsh"

# ── Symlinks ─────────────────────────────────────────────────────
info "linking configs..."

link "$DOTFILES/zsh/.zshrc"               "$HOME/.zshrc"
link "$DOTFILES/zsh/.zimrc"               "$HOME/.zimrc"
link "$DOTFILES/zsh/.zprofile"            "$HOME/.zprofile"
link "$DOTFILES/starship/starship-latte.toml"  "$HOME/.config/starship-latte.toml"
link "$DOTFILES/starship/starship-mocha.toml"  "$HOME/.config/starship-mocha.toml"
link "$DOTFILES/ghostty/config"           "$HOME/.config/ghostty/config"
link "$DOTFILES/zed/settings.json"        "$HOME/.config/zed/settings.json"
link "$DOTFILES/yabai/yabairc"            "$HOME/.config/yabai/yabairc"
link "$DOTFILES/git/.gitconfig"           "$HOME/.gitconfig"

# Zed extensions (catppuccin, typst) auto-install on first launch via
# the auto_install_extensions block in zed/settings.json.

# ── zimfw modules ────────────────────────────────────────────────
# Install modules now that .zimrc is symlinked. Subsequent runs are
# instant (zimfw skips modules that are already up to date).
if [ -f "$ZIM_HOME/zimfw.zsh" ] && [ -f "$HOME/.zimrc" ]; then
    info "installing zimfw modules..."
    if zsh "$ZIM_HOME/zimfw.zsh" install 2>/dev/null; then
        ok "zimfw modules installed"
    else
        warn "zimfw module install had errors — will retry on next shell open"
    fi
fi

# ── atuin (shell history) ────────────────────────────────────────
# atuin replaces Ctrl+R with SQLite-backed history. On first install,
# import existing zsh history.
if command -v atuin &>/dev/null; then
    if [ ! -f "$HOME/.local/share/atuin/history.db" ]; then
        info "initializing atuin (importing zsh history)..."
        atuin import zsh 2>/dev/null || true
        ok "atuin initialized"
    else
        ok "atuin already initialized"
    fi
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
# Syncs CLI tools installed globally via npm.
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
info "applying macOS app defaults..."
defaults write com.mitchellh.ghostty NSQuitAlwaysKeepsWindows -bool false
ok "Ghostty: macOS Resume disabled"

# Skim: auto-reload the PDF when it changes on disk (no dialog), so
# `tw` / `typst watch` gives live preview beside the editor.
defaults write net.sourceforge.skim-app.skim SKAutoReloadFileUpdate -bool true
ok "Skim: auto-reload on file change enabled"

# ── Headless macOS settings ──────────────────────────────────────
# Run with --headless on machines with no display (e.g. Mac Mini server).
# Disables sleep, screensaver, and Spotlight to reduce resource use
# and prevent the machine from becoming unreachable over SSH.
if $HEADLESS; then
    info "applying headless macOS settings (requires interactive sudo)..."
    sudo pmset -a sleep 0          || warn "pmset sleep: needs interactive sudo"
    sudo pmset -a disksleep 0      || warn "pmset disksleep: needs interactive sudo"
    sudo pmset -a hibernatemode 0  || warn "pmset hibernatemode: needs interactive sudo"
    sudo pmset -a autopoweroff 0   || warn "pmset autopoweroff: needs interactive sudo"
    sudo pmset -a womp 1           # wake on network activity
    sudo pmset -a displaysleep 0   || warn "pmset displaysleep: needs interactive sudo"
    defaults write com.apple.screensaver idleTime 0 || true
    defaults -currentHost write com.apple.screensaver idleTime 0 || true
    sudo mdutil -i off / 2>/dev/null || warn "mdutil: needs interactive sudo for Spotlight disable"
    ok "headless: sleep/screensaver/Spotlight settings applied (check skips above)"
fi

# ── Start services ───────────────────────────────────────────────
info "starting services..."
if ! $HEADLESS; then
    yabai --restart-service 2>/dev/null || true
fi

echo ""
ok "done! restart your terminal or run: source ~/.zshrc"
echo ""
