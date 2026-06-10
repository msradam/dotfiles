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

# ── Migrations: uninstall replaced tools ─────────────────────────
# fnm → volta (volta uses shims with no shell hook overhead)
if brew list fnm &>/dev/null 2>&1; then
    info "removing fnm (replaced by volta)..."
    brew uninstall fnm
    ok "fnm removed"
fi

# Oh My Zsh → zimfw (zimfw has <10ms startup vs OMZ's 200-400ms)
if [ -d "$HOME/.oh-my-zsh" ]; then
    info "removing Oh My Zsh (replaced by zimfw)..."
    rm -rf "$HOME/.oh-my-zsh"
    rm -f "$HOME/.zshrc.pre-oh-my-zsh"
    ok "Oh My Zsh removed"
fi

# brew-managed zsh plugins → zimfw modules
for pkg in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
    if brew list "$pkg" &>/dev/null 2>&1; then
        info "removing $pkg from brew (now managed by zimfw)..."
        brew uninstall "$pkg"
        ok "$pkg removed"
    fi
done

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
# Modules are defined in ~/.zimrc (symlinked from dotfiles/zsh/.zimrc).
# The .zshrc self-bootstraps on first open, but we pre-fetch here so
# the shell is fully configured immediately after install.
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

# ── Node.js LTS via volta ────────────────────────────────────────
# volta installs shims — no eval in .zshrc, no per-shell overhead.
if command -v volta &>/dev/null; then
    if ! volta list 2>/dev/null | grep -qi "node"; then
        info "installing Node.js LTS via volta..."
        volta install node@lts 2>&1 | tail -3 || warn "volta node install had errors"
        ok "Node.js LTS installed"
    else
        ok "Node.js already installed via volta"
    fi
fi

# ── Rosé Pine for bat (main + dawn) ─────────────────────────────
# _palette_switch in .zshrc swaps BAT_THEME between "Rose Pine" and
# "Rose Pine Dawn" based on macOS appearance, so both must be present.
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

# ── Rosé Pine for zsh-syntax-highlighting ────────────────────────
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
link "$DOTFILES/zsh/.zimrc"              "$HOME/.zimrc"
link "$DOTFILES/starship/starship-dawn.toml"   "$HOME/.config/starship-dawn.toml"
link "$DOTFILES/starship/starship-main.toml"   "$HOME/.config/starship-main.toml"
link "$DOTFILES/ghostty/config"          "$HOME/.config/ghostty/config"
link "$DOTFILES/yabai/yabairc"           "$HOME/.config/yabai/yabairc"
link "$DOTFILES/git/.gitconfig"          "$HOME/.gitconfig"
link "$DOTFILES/bob/settings.json"       "$HOME/Library/Application Support/IBM Bob/User/settings.json"
link "$DOTFILES/bob/settings.json"       "$HOME/Library/Application Support/Code/User/settings.json"

# ── zimfw modules ────────────────────────────────────────────────
# Install modules now that .zimrc is symlinked. Subsequent runs are
# instant (zimfw skips modules that are already up to date).
if [ -f "$ZIM_HOME/zimfw.zsh" ] && [ -f "$HOME/.zimrc" ]; then
    info "installing zimfw modules..."
    zsh "$ZIM_HOME/zimfw.zsh" install 2>/dev/null \
        && ok "zimfw modules installed" \
        || warn "zimfw module install had errors — will retry on next shell open"
fi

# ── atuin (shell history) ────────────────────────────────────────
# atuin replaces Ctrl+R with SQLite-backed history; optionally syncs
# across machines. On first install, import existing zsh history.
if command -v atuin &>/dev/null; then
    if [ ! -f "$HOME/.local/share/atuin/history.db" ]; then
        info "initializing atuin (importing zsh history)..."
        atuin import zsh 2>/dev/null || true
        ok "atuin initialized"
    else
        ok "atuin already initialized"
    fi
fi

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

# ── VS Code extensions ───────────────────────────────────────────
# Settings are shared with Bob (symlinked above). Extensions use the
# same list; both IDEs are VS Code forks with the same marketplace.
CODE_BIN="$(command -v code 2>/dev/null || true)"
[ -z "$CODE_BIN" ] && CODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

vscode_install_extensions() {
    info "installing VS Code extensions..."
    local failed=0
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        local ext="${line%%#*}"
        ext="${ext// /}"
        [[ -z "$ext" ]] && continue
        if "$CODE_BIN" --install-extension "$ext" --force &>/dev/null; then
            ok "  $ext"
        else
            warn "  $ext (failed — skipped)"
            (( failed++ )) || true
        fi
    done < "$DOTFILES/bob/extensions.txt"
    if [ "$failed" -gt 0 ]; then
        warn "VS Code: $failed extension(s) failed to install"
    fi
}

if [ -x "$CODE_BIN" ]; then
    info "VS Code detected: $CODE_BIN"
    vscode_install_extensions
else
    warn "code CLI not found — install VS Code or run 'Install code command in PATH' from inside VS Code"
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
# Syncs CLI tools installed globally via npm. Requires a Node version
# active via volta (`volta install node@lts` sets the default).
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
    warn "npm not on PATH — run \`volta install node@lts\` first, then re-run"
fi

# ── macOS app defaults ───────────────────────────────────────────
info "applying macOS app defaults..."
defaults write com.mitchellh.ghostty NSQuitAlwaysKeepsWindows -bool false
ok "Ghostty: macOS Resume disabled"

# ── Headless macOS settings ──────────────────────────────────────
# Run with --headless on machines with no display (e.g. Mac Mini server).
# Disables sleep, screensaver, and Spotlight to reduce resource use
# and prevent the machine from becoming unreachable over SSH.
if $HEADLESS; then
    info "applying headless macOS settings (requires interactive sudo)..."
    # These pmset flags prevent the machine from sleeping or hibernating,
    # keeping it reachable over SSH after reboots.
    sudo pmset -a sleep 0       || warn "pmset sleep: needs interactive sudo"
    sudo pmset -a disksleep 0   || warn "pmset disksleep: needs interactive sudo"
    sudo pmset -a hibernatemode 0 || warn "pmset hibernatemode: needs interactive sudo"
    sudo pmset -a autopoweroff 0  || warn "pmset autopoweroff: needs interactive sudo"
    sudo pmset -a womp 1           # wake on network activity
    sudo pmset -a displaysleep 0  || warn "pmset displaysleep: needs interactive sudo"
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
