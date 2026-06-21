#!/bin/bash
set -euo pipefail

if command -v atuin &>/dev/null && [ ! -f "$HOME/.local/share/atuin/history.db" ]; then
    atuin import zsh 2>/dev/null || true
fi
