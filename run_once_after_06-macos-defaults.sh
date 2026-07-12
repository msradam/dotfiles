#!/bin/bash
set -uo pipefail

defaults write com.mitchellh.ghostty NSQuitAlwaysKeepsWindows -bool false \
    || echo "  ⚠️  skipped: Ghostty window default"

# Appearance accent → Catppuccin Mauve (preset "purple"; Tahoe custom-hex is UI-only)
defaults write NSGlobalDomain AppleAccentColor -int 5 \
    || echo "  ⚠️  skipped: accent color (NSGlobalDomain may be managed)"
defaults write -g AppleHighlightColor "0.7961 0.6510 0.9686 Purple" \
    || echo "  ⚠️  skipped: highlight color (NSGlobalDomain may be managed)"
