#!/bin/bash
set -euo pipefail

defaults write com.mitchellh.ghostty NSQuitAlwaysKeepsWindows -bool false

# Appearance accent → Catppuccin Mauve (preset "purple"; Tahoe custom-hex is UI-only)
defaults write NSGlobalDomain AppleAccentColor -int 5
defaults write -g AppleHighlightColor "0.7961 0.6510 0.9686 Purple"
