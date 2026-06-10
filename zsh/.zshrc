# ── Completion styles (must precede zimfw/compinit) ──────────────
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':completion:*:descriptions' format '%F{blue}── %d ──%f'

# ── Volta (Node.js) — must be on PATH before zimfw sees npm completions
export VOLTA_HOME="${HOME}/.volta"
export PATH="${VOLTA_HOME}/bin:${HOME}/.local/bin:${PATH}"

# ── zimfw ─────────────────────────────────────────────────────────
# Self-bootstraps on fresh machines; modules listed in ~/.zimrc
ZIM_HOME="${HOME}/.zim"
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
    curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi
if [[ ! ${ZIM_HOME}/init.zsh -nt ${HOME}/.zimrc ]]; then
    source ${ZIM_HOME}/zimfw.zsh init -q
fi
source ${ZIM_HOME}/init.zsh

# ── History ──────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_REDUCE_BLANKS

# ── IBM Bob IDE CLI (bobide) ─────────────────────────────────────
if [ -d "/Applications/IBM Bob.app/Contents/Resources/app/bin" ]; then
    export PATH="/Applications/IBM Bob.app/Contents/Resources/app/bin:${PATH}"
fi

# ── ESC ESC → prepend sudo (replaces OMZ sudo plugin) ────────────
_sudo_cmd() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N _sudo_cmd
bindkey "\e\e" _sudo_cmd

# ── Modern CLI Tools ─────────────────────────────────────────────
eval "$(fzf --zsh)"        2>/dev/null
eval "$(zoxide init zsh)"  2>/dev/null
eval "$(atuin init zsh)"   2>/dev/null  # replaces Ctrl+R with SQLite history
eval "$(direnv hook zsh)"  2>/dev/null

# ── Rosé Pine palette switcher ───────────────────────────────────
# Picks Starship config + zsh-syntax-highlighting + fzf + bat themes
# based on macOS appearance. Re-runs every prompt so a live
# light↔dark flip swaps all four together.
_FZF_OPTS_COMMON="--border='rounded' --preview-window='border-rounded' \
--prompt='❯ ' --marker='◆' --pointer='▶' \
--separator='─' --scrollbar='│' --info='right'"

_palette_switch() {
    if defaults read -g AppleInterfaceStyle &>/dev/null; then
        export STARSHIP_CONFIG="$HOME/.config/starship-main.toml"
        export BAT_THEME="Rose Pine"
        export FZF_DEFAULT_OPTS=" \
--color=bg+:#26233a,bg:#191724,spinner:#ebbcba,hl:#eb6f92 \
--color=fg:#e0def4,header:#eb6f92,info:#c4a7e7,pointer:#ebbcba \
--color=marker:#c4a7e7,fg+:#e0def4,prompt:#c4a7e7,hl+:#eb6f92 \
--color=selected-bg:#403d52 \
$_FZF_OPTS_COMMON"
        source "$HOME/.zsh/rose-pine-zsh-syntax-highlighting-main.zsh" 2>/dev/null
    else
        export STARSHIP_CONFIG="$HOME/.config/starship-dawn.toml"
        export BAT_THEME="Rose Pine Dawn"
        export FZF_DEFAULT_OPTS=" \
--color=bg+:#f2e9e1,bg:#faf4ed,spinner:#d7827e,hl:#b4637a \
--color=fg:#575279,header:#b4637a,info:#907aa9,pointer:#d7827e \
--color=marker:#907aa9,fg+:#575279,prompt:#907aa9,hl+:#b4637a \
--color=selected-bg:#dfdad9 \
$_FZF_OPTS_COMMON"
        source "$HOME/.zsh/rose-pine-zsh-syntax-highlighting-dawn.zsh" 2>/dev/null
    fi
}
autoload -U add-zsh-hook
add-zsh-hook precmd _palette_switch
_palette_switch  # set initial value before first prompt
eval "$(starship init zsh)" 2>/dev/null

# ── Aliases ──────────────────────────────────────────────────────
# bat is aliased over cat — BAT_STYLE/BAT_PAGING below keep it cat-like
alias cat="bat"

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

# Memory pressure + top consumers
alias mem='memory_pressure && echo "---" && ps aux | sort -nrk 4 | head -10'

# ── Functions ────────────────────────────────────────────────────
mk() {
    mkdir -p "$1" && cd "$1"
}

gclone() {
    local repo="$1"
    local dir="${repo##*/}"
    dir="${dir%.git}"
    git clone "$repo" "$dir" && cd "$dir"
}

gstash() {
    local msg="stash-$(date +%Y%m%d-%H%M%S)"
    [ -n "$1" ] && msg="$msg-$1"
    git stash push -m "$msg"
}

# ── Environment ──────────────────────────────────────────────────
export EDITOR="vim"
export VISUAL="vim"
export LANG=en_US.UTF-8
# BAT_THEME is set by _palette_switch above (per macOS appearance)
export BAT_STYLE="plain"   # no line numbers, no header — cat-like
export BAT_PAGING="never"  # don't pipe through less for short files
