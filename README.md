# dotfiles

Personal macOS configuration for shell, terminal, editor, window manager, and assorted tools.

## Layout

```
ghostty/      Ghostty terminal config
starship/     Starship prompt palettes (dawn + main, auto-switched by macOS appearance)
zsh/          .zshrc, .zprofile, syntax-highlighting theme
git/          .gitconfig
bob/          IBM Bob IDE (VS Code fork) settings.json + extensions list
firefox/      userChrome.css
yabai/        tiling window manager config
fonts/        vendored fonts not available via Homebrew
npm/          global npm package list
Brewfile      Homebrew formulae, casks, taps (authoritative for installed software)
install.sh    idempotent installer — install/upgrade only, never uninstalls
```

## Install

```
git clone https://github.com/msradam/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

On a fresh machine the first run bootstraps Xcode Command Line Tools (GUI prompt) and Homebrew; re-run the script once the CLT install completes.

`install.sh` is idempotent and additive: it installs or upgrades packages and links configs, but never removes anything. Safe to re-run.

## Disclosure

Parts of this repository were authored or refined with the help of LLM assistants (primarily Claude). Configurations, scripts, and commit content have been reviewed and verified by me before landing on `main`.
