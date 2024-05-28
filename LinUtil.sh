#!/bin/bash
# Set color codes
grn='\e[0m\e[0;e2m' # Green
bldgrn='\e[0m\e[1;32m' # Bold Green
red='\e[0m\e[0;31m' # Red
bldred='\e[0m\e[1;31m' # Bold Red
orange='\e[0m\e[0;33m' # Orange
bldorange='\e[0m\e[1;33m' # Bold Orange
rst='\e[0m' # Reset

username="$(whoami)"
home="/home/$username"
installdir="$(pwd)"

font_choices=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--fonts)
            shift
            while [[ $# -gt 0 && ! $1 =~ ^- ]]; do
                font_choices+=("$1")
                shift
            done
            ;;
        *)
            echo -e "${bldorange}Unknown option: $1${rst}"
            exit 1
            ;;
    esac
done

if [[ ${#font_choices[@]} -eq 0 ]]; then
    # User prompt for font selection
    while true; do
        echo -e "${bldgrn}Please select the font(s) you want to install:${rst}"
        echo -e "${grn}1. FiraMono 2. JetBrainsMono 3. Meslo 4. Terminus 5. UbuntuMono"
        read -p "${bldgrn}Enter the number(s) of the font(s) you want to install (e.g., 1 3 5): ${rst}" font_choice

        # Store the font choice for later use
        font_choice_array=($font_choice)
        declare -A font_map=( [1]="fira" [2]="jetbrains" [3]="meslo" [4]="terminus" [5]="ubuntu")
        font_choices=()
        for choice in "${font_choice_array[@]}"; do
            font_choices+=("${font_map[$choice]}")
        done

        if [[ $font_choice =~ ^[1-5\ ]+$ ]]; then
            break
        else
            echo -e "${bldred}Invalid input. You gotta pick a font.${rst}"
        fi
    done
fi

command_exists() {
    command -v $1 >/dev/null 2>&1
}

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo $ID
    else
        echo -e "${bldred}OS detection failed: /etc/os-release not found.${rst}"
        exit 1
    fi
}

pkgs() {
    common_pkgs="zsh vim exa ripgrep bat unzip curl git btop"
    case $1 in
        debian|ubuntu)
            sudo apt update
            sudo apt upgrade -y
            sudo apt install nala -y # Install nala frontend for apt
            sudo nala install -y "$common_pkgs" command-not-found build-essential fd-find
            sh <(curl -L https://nixos.org/nix/install) --daemon            # Install Nix package manager
            . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh     # Source Nix profile to make nix available in current session
            nix-env -iA nixpkgs.neovim nixpkgs.starship nixpkgs.fzf         # Packages that are too old on Debian stable
            ;;
        arch)
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm "$common_pkgs" base-devel fd neovim
            ;;
        fedora|rhel)
            sudo dnf upgrade -y
            sudo dnf install -y "$common_pkgs" dnf-plugins-core fd-find 
            ;;
        opensuse)
            sudo zypper --non-interactive refresh && sudo zypper --non-interactive update
            sudo zypper install -y "$common_pkgs" fd 
            ;;
        *)
            echo -e "${bldred}Unsupported OS, I can't help you here.${rst}"
            exit 1
            ;;
    esac
}

adv_cp_mv() {
    # Install Advanced Copy and Move commands to add progress bars (https://github.com/jarun/advcpmv)
    echo -e "${bldgrn}Installing Advanced Copy and Move commands${rst}"
    curl https://raw.githubusercontent.com/jarun/advcpmv/master/install.sh --create-dirs -o ./advcpmv/install.sh
    (cd advcpmv && sh install.sh)
    echo -e "${bldgrn}Copying advcp to /usr/bin/advcp${rst}"
    sudo cp advcpmv/advcp /usr/bin/advcp
    echo -e "${bldgrn}Copying advmv to /usr/bin/advmv${rst}"
    sudo cp advcpmv/advmv /usr/bin/advmv
}

fonts() {
    declare -A font_urls=(
        [fira]="FiraMono.zip"
        [jetbrains]="JetBrainsMono.zip"
        [meslo]="Meslo.zip"
        [terminus]="Terminus.zip"
        [ubuntu]="UbuntuMono.zip"
    )

    if [[ ! -d $home/.local/share/fonts ]]; then
        mkdir -p $home/.local/share/fonts
    fi

    for font in "$@"; do
        wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/${font_urls[$font]}
        unzip ${font_urls[$font]} -d $home/.local/share/fonts
        rm ${font_urls[$font]}
    done

    fc-cache -f -v # Update fonts
}

colorscripts() {
    git clone https://gitlab.com/dwt1/shell-color-scripts.git
    cd shell-color-scripts
    sudo make install
    sudo rm -rf /opt/shell-color-scripts/colorscripts
    cd $installdir
    sudo cp -r colorscripts /opt/shell-color-scripts/
}

dotfiles() {
    if [[ ! -d $home/.config ]]; then
        mkdir $home/.config
    fi
    cp -r $installdir/config/* $home/.config/
    cp zshrc $home/.zshrc
    source $home/.zshrc
}

od_id=$(detect_os)
pkgs $od_id
fonts "${font_choices[@]}"
colorscripts
dotfiles