# ── Oh My Zsh ────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # using Starship prompt instead

plugins=(
    git
    sudo              # ESC ESC to prepend sudo
    command-not-found
    brew
    macos
)

source $ZSH/oh-my-zsh.sh

# ── External Plugins ─────────────────────────────────────────────
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null
source ~/.zsh/rose-pine-zsh-syntax-highlighting.zsh 2>/dev/null

if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
fi

# ── History ──────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_REDUCE_BLANKS

# ── Completion ───────────────────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':completion:*:descriptions' format '%F{blue}── %d ──%f'

# ── Modern CLI Tools ─────────────────────────────────────────────
eval "$(fzf --zsh)" 2>/dev/null
eval "$(zoxide init zsh)" 2>/dev/null

# Starship: pick palette based on macOS appearance (re-checks every prompt
# so a live light↔dark flip swaps the prompt colors automatically).
_starship_palette_switch() {
    if defaults read -g AppleInterfaceStyle &>/dev/null; then
        export STARSHIP_CONFIG="$HOME/.config/starship-main.toml"
    else
        export STARSHIP_CONFIG="$HOME/.config/starship-dawn.toml"
    fi
}
autoload -U add-zsh-hook
add-zsh-hook precmd _starship_palette_switch
_starship_palette_switch  # set initial value before first prompt
eval "$(starship init zsh)" 2>/dev/null

# ── fzf Rosé Pine ────────────────────────────────────────────────
export FZF_DEFAULT_OPTS=" \
--color=bg+:#26233a,bg:#191724,spinner:#ebbcba,hl:#eb6f92 \
--color=fg:#e0def4,header:#eb6f92,info:#c4a7e7,pointer:#ebbcba \
--color=marker:#c4a7e7,fg+:#e0def4,prompt:#c4a7e7,hl+:#eb6f92 \
--color=selected-bg:#403d52 \
--border='rounded' --preview-window='border-rounded' \
--prompt='❯ ' --marker='◆' --pointer='▶' \
--separator='─' --scrollbar='│' --info='right'"

# ── Aliases ──────────────────────────────────────────────────────
# Note: bat and eza are intentionally NOT aliased over cat/ls.
# Invoke them by name when syntax highlighting / icons are wanted.

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

alias gs="git status"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph --decorate -20"
alias gd="git diff"
alias ga="git add"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gst="git stash"
alias gsp="git stash pop"

alias zshrc="$EDITOR ~/dotfiles/zsh/.zshrc"
alias reload="source ~/.zshrc"
alias dots="cd ~/dotfiles"
alias py="python3"
alias c="clear"

# Colima (Docker backend) with 16GB-machine defaults
alias dstart='colima start --memory 4 --cpu 2 --disk 30'
alias dstop='colima stop'

# Memory pressure + top consumers (macOS ps lacks --sort, use sort)
alias mem='memory_pressure && echo "---" && ps aux | sort -nrk 4 | head -10'

# ── Functions ─────────────────────────────────────────────────────────
# Create directory and cd into it
mk() {
    mkdir -p "$1" && cd "$1"
}

# Clone repo and cd into it
gclone() {
    local repo="$1"
    local dir="${repo##*/}"
    dir="${dir%.git}"
    git clone "$repo" "$dir" && cd "$dir"
}

# Stash with auto-message (date + optional note)
gstash() {
    local msg="stash-$(date +%Y%m%d-%H%M%S)"
    [ -n "$1" ] && msg="$msg-$1"
    git stash push -m "$msg"
}

# ── Environment ──────────────────────────────────────────────────
export EDITOR="vim"
export VISUAL="vim"
export LANG=en_US.UTF-8
export BAT_THEME="Rose Pine"

# ── fnm (Fast Node Manager) ────────────────────────────────────────
eval "$(fnm env --use-on-cd 2>/dev/null)" || true

# ── PATH ─────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# IBM Bob IDE CLI (`bobide`) — VS Code-fork's `code` equivalent
if [ -d "/Applications/IBM Bob.app/Contents/Resources/app/bin" ]; then
    export PATH="/Applications/IBM Bob.app/Contents/Resources/app/bin:$PATH"
fi
