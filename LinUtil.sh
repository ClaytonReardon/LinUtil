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

# Prompt for installation type
while true; do
    echo -e "\n${bldgrn}GUI or TTY installation?"
    echo -e "${grn}1. GUI"
    echo -e "2. TTY${rst}"

    read -p "Enter choice: " ux_choice

    if [[ -n "$ux_choice" ]]; then
        break
    else
        echo -e "${bldorange}You gotta pick somethin${rst}"
    fi
done

command_exists() {
    command -v $1 >/dev/null 2>&1
}

checkEnv() {
    ## Check for requirements.
    REQUIREMENTS='curl groups sudo'
    if ! command_exists ${REQUIREMENTS}; then
        echo -e "${bldred}To run me, you need: ${REQUIREMENTS}${rst}"
        exit 1
    fi

    ## Check Package Handeler
    PACKAGEMANAGER='apt yum dnf pacman zypper'
    for pgm in ${PACKAGEMANAGER}; do
        if command_exists ${pgm}; then
            PACKAGER=${pgm}
            echo -e "Using ${pgm}"
        fi
    done

    if [ -z "${PACKAGER}" ]; then
        echo -e "${RED}Can't find a supported package manager"
        exit 1
    fi

    ## Check if the current directory is writable.
    GITPATH="$(dirname "$(realpath "$0")")"
    if [[ ! -w ${GITPATH} ]]; then
        echo -e "${bldred}Can't write to ${GITPATH}${Rrst}"
        exit 1
    fi

    ## Check SuperUser Group
    SUPERUSERGROUP='wheel sudo root'
    for sug in ${SUPERUSERGROUP}; do
        if groups | grep ${sug}; then
            SUGROUP=${sug}
            echo -e "Super user group ${SUGROUP}"
        fi
    done

    ## Check if member of the sudo group.
    if ! groups | grep ${SUGROUP} >/dev/null; then
        echo -e "${RED}You need to be a member of the sudo group to run me!"
        exit 1
    fi

}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        case "$ID" in 
            debian|ubuntu)
                PKG_MAN="nala"
                UPDATE="sudo nala upgrade -y"
                UPGRADE=""
                INSTALL="sudo nala install -y"
                ;;
            arch)
                PKG_MAN="pacman"
                UPDATE="sudo pacman -Syu --noconfirm"
                UPGRADE=""
                INSTALL="sudo pacman -S --noconfirm"
                ;;
            fedora)
                PKG_MAN="dnf"
                UPDATE="sudo dnf upgrade -y"
                UPGRADE=""
                INSTALL="sudo dnf install -y"
                ;;
            opensuse)
                PKG_MAN="zypper"
                UPDATE="sudo zypper update -y"
                UPGRADE=""
                INSTALL="sudo zypper install -y"
                ;;
            rhel)
                PKG_MAN="yum"
                UPDATE="sudo yum upgrade -y"
                UPGRADE=""
                INSTALL="sudo yum install -y"
                ;;
            *)
                echo "Unsupported OS, I can't help you here."
                exit 1
                ;;
        esac
    else
        echo "OS detection failed: /etc/os-release not found."
        exit 1
    fi
}

update_pkgs() {
    echo -e "${bldgrn}Updating package list...${rst}"
    detect_os
    case "$ID" in
        debian|ubuntu)
            echo -e "${bldgrn}Installing Nala.${rst}"
            sudo apt update && sudo apt upgrade -y && sudo apt install nala -y
            ;;
        *)
            $UPGRADE
            ;;
        esac    
}

install_pkgs() {
    echo -e "${bldgrn}Installing common packages${rst}"
    $INSTALL zsh exa unzip curl git
    detect_os
    case "$ID" in
        debian|ubuntu)
            echo -e "${bldgrn}Installing Debian specific packages${rst}"
            $INSTALL fd-find ripgrep bat build-essential btop trash-cli
            ;;
        arch)
            echo -e "${bldgrn}Installing Arch specific packages${rst}"
            $INSTALL fd ripgrep bat btop trash-cli
            $INSTALL --needed base-devel
            ;;
        fedora)
            echo -e "${bldgrn}Installing Fedora specific packages${rst}"
            $INSTALL fd-find ripgrep bat btop trash-cli
            sudo dnf groupinstall "Development Tools" -y
            ;;
        opensuse)
            echo -e "${bldgrn}Installing OpenSUSE specific packages${rst}"
            $INSTALL fd ripgrep bat btop
            sudo zypper install --type pattern devel_basis -y
            ;;
        rhel)
            echo -e "${bldgrn}Installing RHEL specific packages${rst}"
            sudo dnf groupinstall "Development Tools" -y
            # Install fd-find
            sudop dnf copr enable tkbcopr/fd -y
            sudo dnf install fd -f
            # Install ripgrep
            sudo yum install yum-utils -y
            sudo yum-config-manager --add-repo=https://copr.fedorainfracloud.org/coprs/carlwgeorge/ripgrep/repo/epel-7/carlwgeorge-ripgrep-epel-7.repo
            sudo yum install ripgrep -y
            # Install bat
            wget https://github.com/sharkdp/bat/releases/download/v0.23.0/bat-v0.23.0-x86_64-unknown-linux-gnu.tar.gz
            tar -xvf bat-v0.23.0-x86_64-unknown-linux-gnu.tar.gz
            sudo mv bat-v0.23.0-x86_64-unknown-linux-gnu/bat /usr/bin/bat
            rm -r bat-v0.23.0-x86_64-unknown-linux-gnu.tar.gz
            # Install btop
            sudo dnf install epel-release -y
            sudo dnf install btop -y
    esac
}

main() {
    detect_os
    update_pkgs
    install_pkgs
    # Move zshrc and starship.toml to correct location
    cp zshrc ~/.zshrc
    if [ ! -d ~/.config ]; then
        mkdir ~/.config
    fi 
    cp starship.toml ~/.config/starship.toml
}

main