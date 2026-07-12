#!/bin/bash
set -euo pipefail

command -v bat &>/dev/null || exit 0

BAT_THEMES="$(bat --config-dir)/themes"
mkdir -p "$BAT_THEMES"

_fetch() {
    local name="$1" dst="$BAT_THEMES/$1.tmTheme"
    [ -f "$dst" ] && return
    curl -fsSL -o "$dst" \
        "https://raw.githubusercontent.com/catppuccin/bat/main/themes/${name// /%20}.tmTheme" \
        || rm -f "$dst"
}

_fetch "Catppuccin Latte"
_fetch "Catppuccin Mocha"
bat cache --build >/dev/null 2>&1 || true
