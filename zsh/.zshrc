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

# ── Completion styles ─────────────────────────────────────────────
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':completion:*:descriptions' format '%F{blue}── %d ──%f'

# ── sudo widget (ESC ESC toggles a leading sudo) ─────────────────
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

# ── History ──────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_REDUCE_BLANKS

# ── Modern CLI Tools ─────────────────────────────────────────────
command -v fzf    >/dev/null && eval "$(fzf --zsh)"
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
command -v atuin  >/dev/null && eval "$(atuin init zsh --disable-up-arrow)"  # Ctrl+R only; up arrow stays normal
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# ── Catppuccin palette switcher ──────────────────────────────────
# Picks Starship config + zsh-syntax-highlighting + fzf + bat themes
# based on macOS appearance. Re-runs every prompt so a live
# light↔dark flip swaps all four together.
_FZF_OPTS_COMMON="--border='rounded' --preview-window='border-rounded' \
--prompt='❯ ' --marker='◆' --pointer='▶' \
--separator='─' --scrollbar='│' --info='right'"

_palette_switch() {
    if defaults read -g AppleInterfaceStyle &>/dev/null; then
        export STARSHIP_CONFIG="$HOME/.config/starship-mocha.toml"
        export BAT_THEME="Catppuccin Mocha"
        export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
$_FZF_OPTS_COMMON"
        source "$HOME/.zsh/catppuccin-zsh-syntax-highlighting-mocha.zsh" 2>/dev/null
    else
        export STARSHIP_CONFIG="$HOME/.config/starship-latte.toml"
        export BAT_THEME="Catppuccin Latte"
        export FZF_DEFAULT_OPTS=" \
--color=bg+:#ccd0da,bg:#eff1f5,spinner:#dc8a78,hl:#d20f39 \
--color=fg:#4c4f69,header:#d20f39,info:#8839ef,pointer:#dc8a78 \
--color=marker:#7287fd,fg+:#4c4f69,prompt:#8839ef,hl+:#d20f39 \
--color=selected-bg:#bcc0cc \
$_FZF_OPTS_COMMON"
        source "$HOME/.zsh/catppuccin-zsh-syntax-highlighting-latte.zsh" 2>/dev/null
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

# Typst live preview: compile + watch a .typ, open the PDF in Skim.
# Skim auto-reloads on disk change (SKAutoReloadFileUpdate), so this
# gives a real native PDF preview beside the editor. Ctrl-C to stop.
tw() {
    local src="${1:?usage: tw file.typ}"
    local pdf="${src%.typ}.pdf"
    typst compile "$src" "$pdf" || return 1
    open -a Skim "$pdf"
    typst watch "$src" "$pdf"
}

# ── Environment ──────────────────────────────────────────────────
export EDITOR="vim"
export VISUAL="vim"
export LANG=en_US.UTF-8
# BAT_THEME is set by _palette_switch above (per macOS appearance).
export BAT_STYLE="plain"     # no line numbers, no header — cat-like
export BAT_PAGING="never"    # don't pipe through less for short files

# ── fnm (Fast Node Manager) ──────────────────────────────────────
eval "$(fnm env --use-on-cd 2>/dev/null)" || true

# ── PATH ─────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# bun completions
[ -s "/Users/amsrahman/.bun/_bun" ] && source "/Users/amsrahman/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
