# Set Zinit directory, and install if needed
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Add zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in Snippets
zinit snippet OMZP::command-not-found

autoload -Uz compinit && compinit

zinit cdreplay -q

# Keybindings
# Search command history while keeping current command
bindkey '^[[1;5A' history-search-backward
bindkey '^[[1;5B' history-search-forward

# History
HISTSIZE=9000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion Styling
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -gh $realpath'

# Aliases
alias ls='exa -gh'
alias install='sudo nala install'
alias search='nala search'
alias vim='nvim'
alias bat='batcat'
alias rm='trash'
alias grep='grep --color=auto'
alias ip='ip --color=auto'
alias diff='diff --color=auto'

# Check if `advcp` and `advmv` are installed, and install if not
command_exists() {
    command -v "$1" > /dev/null 2>&1
}
if ! command_exists advcp || ! command_exists advmv; then
    echo -e "\e[1;32madvcp or advmv not found. Installing...\e[0m"
    curl https://raw.githubusercontent.com/jarun/advcpmv/master/install.sh --create-dirs -o ./advcpmv/install.sh
    (cd advcpmv && sh install.sh)
    echo -e "\e[1;32mCopying advcp to /usr/bin/advcp\e[0m"
    sudo cp advcpmv/advcp /usr/bin/advcp
    echo -e "\e[1;32mCopying advmv to /usr/bin/advmv\e[0m"
    sudo cp advcpmv/advmv /usr/bin/advmv
fi

alias cp='advcp -gi' # Copy w prog bar & overwrite confirmation
alias mv='advmv -gi' # Move w prog bar & overwrite confirmation

# Change Manpager from Less to Batcat
export MANPAGER='/bin/batcat --wrap=character'

# Set Path
export PATH="$PATH:$HOME/.local/bin"


# Shell Integrations
eval "$(starship init zsh)"
source <(fzf --zsh)
eval "$(zoxide init --cmd cd zsh)"

# Colorscript at shell startup
colorscript -r