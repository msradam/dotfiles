#!/bin/bash
set -uo pipefail

if command -v yabai &>/dev/null; then
    yabai --restart-service 2>/dev/null \
        || echo "  ⚠️  yabai not started — grant Accessibility, then run: yabai --start-service"
else
    echo "  ⚠️  skipped: yabai not installed"
fi
