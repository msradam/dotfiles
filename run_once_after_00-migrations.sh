#!/bin/bash
set -uo pipefail

# Oh My Zsh → zimfw
if [ -d "$HOME/.oh-my-zsh" ]; then
    rm -rf "$HOME/.oh-my-zsh" "$HOME/.zshrc.pre-oh-my-zsh"
fi

# brew-managed zsh plugins → zimfw modules
for pkg in zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
    brew list "$pkg" &>/dev/null 2>&1 && \
        brew uninstall --ignore-dependencies "$pkg" 2>/dev/null || true
done

# IBM Bob
if [ -d "/Applications/IBM Bob.app" ]; then
    osascript -e 'quit app "IBM Bob"' 2>/dev/null || true
    rm -rf "/Applications/IBM Bob.app"
fi
rm -rf "$HOME/Library/Application Support/IBM Bob" "$HOME/.bob" 2>/dev/null || true

# bobshell npm global
if command -v npm &>/dev/null && npm ls -g --depth=0 bobshell &>/dev/null; then
    npm uninstall -g bobshell &>/dev/null || true
fi

# Zed → VS Code
if [ -d "/Applications/Zed.app" ]; then
    osascript -e 'quit app "Zed"' 2>/dev/null || true
    rm -rf "/Applications/Zed.app"
fi

# Stale Rosé Pine assets
rm -f "$HOME/.config/starship-main.toml" "$HOME/.config/starship-dawn.toml" \
      "$HOME/.zsh/rose-pine-zsh-syntax-highlighting-main.zsh" \
      "$HOME/.zsh/rose-pine-zsh-syntax-highlighting-dawn.zsh" 2>/dev/null || true
if command -v bat &>/dev/null; then
    _bat_themes="$(bat --config-dir)/themes"
    rm -f "$_bat_themes/Rose Pine.tmTheme" "$_bat_themes/Rose Pine Dawn.tmTheme" 2>/dev/null || true
fi
