#!/bin/bash
set -euo pipefail

defaults write com.mitchellh.ghostty NSQuitAlwaysKeepsWindows -bool false
defaults write net.sourceforge.skim-app.skim SKAutoReloadFileUpdate -bool true
