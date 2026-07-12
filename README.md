# dotfiles

Personal macOS configuration managed with [chezmoi](https://chezmoi.io). Covers the shell (zsh + zimfw), terminal (Ghostty), editors (VS Code and Neovim/LazyVim), window manager (yabai + JankyBorders), prompt (Starship), and assorted CLI tools. The theme is Catppuccin (Latte/Mocha), auto-switching with the macOS light/dark appearance.

## Install

Requires macOS. On a fresh machine:

```
xcode-select --install                                   # git + compiler
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install chezmoi
git clone https://github.com/msradam/dotfiles.git ~/dotfiles
chezmoi init --source ~/dotfiles
chezmoi apply
```

The source directory is `~/dotfiles` (set in `.chezmoi.toml.tmpl`), not chezmoi's default `~/.local/share/chezmoi`, so `--source ~/dotfiles` is required on first `init`. After that, `chezmoi apply` uses it automatically.

`chezmoi apply` renders the templates into `$HOME` and runs the `run_*` scripts: install everything in the `Brewfile`, set up zimfw, uv-managed Python, atuin, Catppuccin bat themes, npm globals, VS Code extensions, macOS defaults, Firefox userChrome/userContent, and start the yabai and borders services.

## Usage

chezmoi is the single entry point:

```
chezmoi apply              # render configs, run changed scripts
chezmoi diff               # preview what apply would change
chezmoi edit <file>        # edit a managed file in the source
chezmoi re-add             # pull live edits back into the source
```

The `Brewfile` is authoritative for installed software. Edit it and run `chezmoi apply` (or `brew bundle --file ~/dotfiles/Brewfile`) to install additions. It installs and upgrades only; it does not uninstall.

## Structure

chezmoi source-state naming: `dot_foo` becomes `~/.foo`, `executable_` keeps the +x bit, `run_once_after_*` runs once after apply, `run_onchange_*` re-runs when a file it references changes, and `*.tmpl` is templated.

```
.chezmoi.toml.tmpl     per-host data (code font size by hostname)
.chezmoiignore         source files consumed by scripts, not written to $HOME
.chezmoiremove         paths chezmoi removes on apply
Brewfile               Homebrew formulae, casks, taps (authoritative)
dot_zshrc              shell: rc, login profile, zimfw module list
dot_zprofile
dot_zimrc
dot_gitconfig          git
dot_config/            ghostty, nvim, yabai, borders, btop, yazi, lazygit, starship
Library/.../Code/      VS Code settings.json (templated)
firefox/               userChrome.css + userContent.css (applied by a run script)
fonts/                 vendored fonts not available on Homebrew
npm/  vscode/          package lists consumed by run scripts
run_*                  install and bootstrap scripts
```

## Configuration

Per-host values live in `.chezmoi.toml.tmpl`. It sets `codeFontSize` by hostname (20 on the host named `Mac`, 19 elsewhere), consumed by the Ghostty and VS Code templates. Add hosts there as needed.
