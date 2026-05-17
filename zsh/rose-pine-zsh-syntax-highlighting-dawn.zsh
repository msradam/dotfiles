# Rosé Pine Dawn theme for zsh-syntax-highlighting (light mode).
# Source this from ~/.zshrc *after* zsh-syntax-highlighting is loaded.
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main cursor)
typeset -gA ZSH_HIGHLIGHT_STYLES

# Palette (Rosé Pine Dawn):
#   base #faf4ed  text #575279  subtle #797593  muted #9893a5
#   love #b4637a  gold #ea9d34  rose #d7827e
#   pine #286983  foam #56949f  iris #907aa9

## Comments
ZSH_HIGHLIGHT_STYLES[comment]='fg=#9893a5'
## Functions / commands
ZSH_HIGHLIGHT_STYLES[alias]='fg=#56949f'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#56949f'
ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#56949f'
ZSH_HIGHLIGHT_STYLES[function]='fg=#56949f'
ZSH_HIGHLIGHT_STYLES[command]='fg=#56949f'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#56949f,italic'
ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=#ea9d34,italic'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#ea9d34'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#ea9d34'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#907aa9'
## Built-ins / keywords
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#56949f'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#56949f'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#56949f'
## Punctuation
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#b4637a'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg=#575279'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter-unquoted]='fg=#575279'
ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg=#575279'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]='fg=#b4637a'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=#b4637a'
ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=#b4637a'
## Strings
ZSH_HIGHLIGHT_STYLES[command-substitution-quoted]='fg=#ea9d34'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter-quoted]='fg=#ea9d34'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#ea9d34'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument-unclosed]='fg=#b4637a'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#ea9d34'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument-unclosed]='fg=#b4637a'
ZSH_HIGHLIGHT_STYLES[rc-quote]='fg=#ea9d34'
## Variables
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#575279'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument-unclosed]='fg=#b4637a'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#575279'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#575279'
ZSH_HIGHLIGHT_STYLES[named-fd]='fg=#575279'
ZSH_HIGHLIGHT_STYLES[numeric-fd]='fg=#575279'
## Paths / misc
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#b4637a'
ZSH_HIGHLIGHT_STYLES[path]='fg=#575279,underline'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#b4637a,underline'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#575279,underline'
ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg=#b4637a,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#575279'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#907aa9'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-unclosed]='fg=#b4637a'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#575279'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#575279'
ZSH_HIGHLIGHT_STYLES[default]='fg=#575279'
ZSH_HIGHLIGHT_STYLES[cursor]='fg=#575279'
