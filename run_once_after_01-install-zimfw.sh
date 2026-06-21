#!/bin/bash
set -euo pipefail

ZIM_HOME="$HOME/.zim"
if [ ! -f "$ZIM_HOME/zimfw.zsh" ]; then
    mkdir -p "$ZIM_HOME"
    curl -fsSL -o "$ZIM_HOME/zimfw.zsh" \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh || true
fi

if [ -f "$ZIM_HOME/zimfw.zsh" ] && [ -f "$HOME/.zimrc" ]; then
    zsh "$ZIM_HOME/zimfw.zsh" install 2>/dev/null || true
fi
