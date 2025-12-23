# Added to make direnv work with powerlevel10k
(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv export zsh)"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Added to make direnv work with powerlevel10k
# direnv lets you automatically customize env variables in certian folders
# with the .envrc file
(( ${+commands[direnv]} )) && emulate zsh -c "$(direnv hook zsh)"


# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab 

# Enable completions
autoload -Uz compinit && compinit
zinit cdreplay -q

# Completion styling
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:*' fzf-min-height '20'
zstyle ':fzf-tab:complete:cd:*' continuous-trigger enter
zstyle ':fzf-tab:complete:*' fzf-flags --preview-window=right:65%

# Git completions
# export COLUMNS # uncomment if delta (git diff preview) starts not filling the preview window
# export FZF_PREVIEW_COLUMNS # --//--
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
	'git diff $word | delta -w ${FZF_PREVIEW_COLUMNS-$COLUMNS}'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
	'git log --color=always $word'
zstyle ':fzf-tab:complete:git-help:*' fzf-preview \
	'git help $word | bat -plman --color=always'
zstyle ':fzf-tab:complete:git-show:*' fzf-preview \
	'case "$group" in
	"commit tag") git show --color=always $word ;;
	*) git show --color=always $word | delta -w ${FZF_PREVIEW_COLUMNS-$COLUMNS} ;;
	esac'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
	'case "$group" in
	"modified file") git diff $word | delta -w ${FZF_PREVIEW_COLUMNS-$COLUMNS} ;;
	"recent commit object name") git show --color=always $word | delta -w ${FZF_PREVIEW_COLUMNS-$COLUMNS} ;;
	*) git log --color=always $word ;;
	esac'

# Brew completions
zstyle ':fzf-tab:complete:brew-(install|uninstall|search|info):*-argument-rest' fzf-preview 'brew info $word'

# Fallback completions (handles text files, folders (optional: images))
zstyle ':fzf-tab:complete:*:*' fzf-preview 'less ${(Q)realpath}'
export LESSOPEN='|~/.lessfilter %s'
# Set bat as man pages colorizer
export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# completion using arrow keys (based on history)
# overriden by atuin anyway
#bindkey '^[[A' history-search-backward
#bindkey '^[[B' history-search-forward

alias ls="eza --icons=always" # eza is a better looking ls
alias cat="bat" # dropin cat with syntax highlighting
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain' # use bat to collor <command> --help
alias n="nvim"
alias t="tmux"
alias lg="lazygit"

# Better shell history (atuin)
eval "$(atuin init zsh)"

# Better cd with path caching and matching
eval "$(zoxide init zsh --cmd cd)"

# fuzzy finder used for tab completion
eval "$(fzf --zsh)"

# Automatically load custom values into PATH when entering a directory
# with a .envrc file.
# eval "$(direnv hook zsh)"


# Android studio variables
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/benjaminjurewicz/.lmstudio/bin"
# End of LM Studio CLI section

