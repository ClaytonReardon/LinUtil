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

directory_exists() {
    [[ -d "$1" ]]
}

file_exists() {
    [[ -f "$1" ]]
}

if ! command_exists nala; then
    echo "Nala not found. Installing..."
    sudo apt install nala -y
fi

if ! command_exists nvim; then
    echo "Neovim not found. Installing..."
    sudo nala install neovim -y
fi

if ! command_exists batcat; then
    echo "Bat not found. Installing..."
    sudo nala install bat -y
fi

if ! command_exists trash; then
    echo "Trash-cli not found. Installing..."
    sudo nala install trash-cli -y
fi

if ! command_exists fzf; then
    echo "Fzf not found. Installing..."
    sudo nala install fzf -y
fi

if ! command_exists starship; then
    echo "Starship not found. Installing..."
    curl -sS https://starship.rs/install.sh | bash
fi

if ! directory_exists ~/.config; then
    echo ".config directory not found. Creating..."
    mkdir -p ~/.config
fi

if ! file_exists ~/.config/starship.toml; then
    echo "Starship config not found. Downloading..."
    wget https://github.com/ClaytonReardon/LinUtil/raw/refs/heads/main/config/starship.toml -O ~/.config/starship.toml
fi

# Change Manpager from Less to Batcat
export MANPAGER='/bin/batcat --wrap=character'

# Set Path
export PATH="$PATH:$HOME/.local/bin"


# Shell Integrations
eval "$(starship init zsh)"
