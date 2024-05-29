#!/bin/bash
# Set color codes
grn='\e[0m\e[0;32m' # Green
bldgrn='\e[0m\e[1;32m' # Bold Green
red='\e[0m\e[0;31m' # Red
bldred='\e[0m\e[1;31m' # Bold Red
orange='\e[0m\e[0;33m' # Orange
bldorange='\e[0m\e[1;33m' # Bold Orange
rst='\e[0m' # Reset

username="$(whoami)"
home="/home/$username"
installdir="$(pwd)"

unattended=false

usage() {
    echo -e "Usage: $0 [OPTIONS]"
    echo -e "Options:"
    echo -e "   -f, --fonts     Specify the fonts to install (e.g. fira jetbrains meslo terminus ubuntu)"
    echo -e "   -h, --help      Display this help message"
    exit 0
}

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
        -u|--unattended)
            unattended=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${bldorange}Unknown option: $1${rst}"
            usage
            exit 1
            ;;
    esac
done

if [[ ${#font_choices[@]} -eq 0 ]]; then
    if $unattended; then
        font_choices+=("jetbrains")
    else
    # User prompt for font selection
        while true; do
            echo -e "${bldgrn}Please select the font(s) you want to install:"
            echo -e "${grn}1. FiraMono 2. JetBrainsMono 3. Meslo 4. Terminus 5. UbuntuMono${rst}"
            read -p "Enter the number(s) of the font(s) you want to install (e.g., 1 3 5): " font_choice

            if [ -z "$font_choice" ]; then
                font_choice="2" # Default to JetBrainsMono
            fi

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
                echo -e "${bldred}Invalid input. Select a number 1-5${rst}"
            fi
        done
    fi
fi

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
    common_pkgs="zsh vim exa ripgrep bat unzip curl git btop trash-cli"
    case $1 in
        debian|ubuntu)
            echo -e "${bldgrn}Updating package lists and upgrading packages${rst}"
            sudo apt update
            sudo apt upgrade -y

            echo -e "${bldgrn}Installing Nala ${grn}(frontend for apt)${rst}"
            sudo apt install nala -y # Install nala frontend for apt
            
            echo -e "${bldgrn}Installing packages${rst}"
            sudo nala install -y $common_pkgs command-not-found build-essential fd-find console-setup
            
            echo -e "${bldgrn}Installing Nix package manager${rst}"
            {   # Arguments to be passed to Nix installer
                echo "n"
                echo "y"
                echo "y"
                echo ""
            } | sh <(curl -L https://nixos.org/nix/install) --daemon

            echo -e "${bldgrn}Sourching Nix profile to make Nix available in this session${rst}"
            . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 

            echo -e "${bldgrn}Installing packages with Nix ${grn}(Neovim, Starship Prompt, FZF, Zoxide)${rst}"
            nix-env -iA nixpkgs.neovim nixpkgs.fzf # Packages that are too old on Debian stable

            # Install Starship Prompt
            echo -e "${bldgrn}Installing Starship Prompt${rst}"
            yes | curl -sS https://starship.rs/install.sh | sh

            # Install Zoxide
            echo -e "${bldgrn}Installing Zoxide${rst}"
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
            ;;
        arch)
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm $common_pkgs base-devel fd neovim kbd
            # Install Starship Prompt
            echo -e "${bldgrn}Installing Starship Prompt${rst}"
            curl -sS https://starship.rs/install.sh | sh
            # Install Zoxide
            echo -e "${bldgrn}Installing Zoxide${rst}"
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
            ;;
        fedora|rhel)
            sudo dnf upgrade -y
            sudo dnf install -y $common_pkgs dnf-plugins-core fd-find kbd
            # Install Starship Prompt
            echo -e "${bldgrn}Installing Starship Prompt${rst}"
            curl -sS https://starship.rs/install.sh | sh
            # Install Zoxide
            echo -e "${bldgrn}Installing Zoxide${rst}"
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
            ;;
        opensuse)
            sudo zypper --non-interactive refresh && sudo zypper --non-interactive update
            sudo zypper install -y $common_pkgs fd kbd
            # Install Starship Prompt
            echo -e "${bldgrn}Installing Starship Prompt${rst}"
            curl -sS https://starship.rs/install.sh | sh
            # Install Zoxide
            echo -e "${bldgrn}Installing Zoxide${rst}"
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
            ;;
        *)
            echo -e "${bldred}Unsupported OS, I can't help you here.${rst}"
            exit 1
            ;;
    esac
}

fonts() {
    declare -A font_urls=(
        [fira]="FiraMono.zip"
        [jetbrains]="JetBrainsMono.zip"
        [meslo]="Meslo.zip"
        [terminus]="Terminus.zip"
        [ubuntu]="UbuntuMono.zip"
    )

    # Make fonts directory if it doesn't exist
    if [[ ! -d $home/.local/share/fonts ]]; then
        mkdir -p $home/.local/share/fonts
    fi

    # Install selected fonts
    for font in "$@"; do
        echo -e "${bldgrn}Installing ${font_urls[$font^]}${rst}"
        wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/${font_urls[$font]}
        unzip -o ${font_urls[$font]} -d $home/.local/share/fonts
        rm ${font_urls[$font]}
    done

    # Update fonts
    fc-cache -f -v
}

adv_cp_mv() {
    # Install Advanced Copy and Move commands to add progress bars (https://github.com/jarun/advcpmv)
    echo -e "${bldgrn}Installing Advanced Copy and Move commands ${grn}(Adds progress bars)${rst}"
    curl https://raw.githubusercontent.com/jarun/advcpmv/master/install.sh --create-dirs -o ./advcpmv/install.sh
    (cd advcpmv && sh install.sh)
    echo -e "${bldgrn}Copying advcp to /usr/bin/advcp${rst}"
    sudo cp advcpmv/advcp /usr/bin/advcp
    echo -e "${bldgrn}Copying advmv to /usr/bin/advmv${rst}"
    sudo cp advcpmv/advmv /usr/bin/advmv
}

colorscripts() {
    echo -e "${bldgrn}Installing shell-color-scripts${rst}"
    git clone https://gitlab.com/dwt1/shell-color-scripts.git
    cd shell-color-scripts
    sudo make install
    sudo rm -rf /opt/shell-color-scripts/colorscripts
    cd $installdir
    sudo cp -r colorscripts /opt/shell-color-scripts/
}

dotfiles() {
    echo -e "${bldgrn}Copying dotfiles${rst}"

    # If .config directory doesn't exist, create it
    if [[ ! -d $home/.config ]]; then
        mkdir $home/.config
    fi

    # Copy dotfiles
    cp -r $installdir/config/* $home/.config/
    cp zshrc $home/.zshrc
    echo -e "${bldgrn}Sourcing zshrc & installing zinit plugins${rst}"
}

os_id=$(detect_os)
echo -e "Detected ${bldgrn}$os_id${rst}"
pkgs $os_id
fonts "${font_choices[@]}"
adv_cp_mv
colorscripts
dotfiles
exec zsh