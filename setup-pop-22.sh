#!/bin/bash

# Sets up on a new machine with Pop!_OS 22.04

#******************************************************************************
#
#******************************************************************************
print_banner()
{
    echo ""
    echo "################################################################"
    echo "##"
    echo "##  $1"
    echo "##"
    echo "################################################################"
}

print_small_banner()
{
    echo ""
    echo "########################################################"
    echo "#  $1"
    echo "########################################################"
}

func_begin()
{
    print_small_banner "$1"
    set -x
}

func_done()
{
    set +x
    echo "Done"
    echo ""
}

#******************************************************************************
#
#******************************************************************************
install_basic_packages() {
    func_begin "Installing basic packages"

    sudo apt-get update
    sudo apt-get install -y \
        git \
        git-lfs \
        kitty \
        cmake \
        build-essential \
        ranger \
        stow \
        virtualenvwrapper \
        silversearcher-ag \
        ripgrep \
        luarocks \
        imagemagick \
        libmagickwand-dev \
        luajit \
        rofi \
        picom \
        direnv \
        xsel \
        xclip

    func_done
}

install_starship() {
    func_begin "Installing Starship"

    curl -sS https://starship.rs/install.sh | sh -s -- --yes

    pushd ~/dotfiles
    stow -v starship
    func_done
}

backup_bash_files() {
    pushd ~
    if [[ -f .bashrc ]]; then
        echo "Backing up existing .bashrc"
        mv .bashrc .bashrc.bak
    fi
    if [[ -f .profile ]]; then
        echo "Backing up existing .profile"
        mv .profile .profile.bak
    fi
    if [[ -f .bash_profile ]]; then
        echo "Backing up existing .bash_profile"
        mv .bash_profile .bash_profile.bak
    fi
    if [[ -f .bash_logout ]]; then
        echo "Backing up existing .bash_logout"
        mv .bash_logout .bash_logout.bak
    fi
    popd
}


install_dotfiles() {
    func_begin "Installing dotfiles"

    pushd ~
    git clone --recurse-submodules -j8 git@github.com:Stefantb/dotfiles.git

    # Creating directories prevents stow from taking ownership, and thus clashes.
    mkdir -p .local/bin
    mkdir -p .config/bash/bashrc.d

    pushd dotfiles
    # Use stow to symlink the dotfiles
    stow -v kitty
    stow -v ranger
    sudo stow -v -t / system_commands

    backup_bash_files
    stow -v bash

    popd # dotfiles
    func_done
}


install_notes() {
    func_begin "Installing notes and git sync"

    pushd ~/dev/
    git clone git@github.com:Stefantb/notes.git
    popd

    pushd ~/dotfiles
    ./setup-notes-git-sync.sh
    popd 
    func_done
}


install_fzf() {
    func_begin "Installing fzf"

    pushd ~
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
    popd

    mkdir -p dev/local-tools/
    pushd dev/local-tools
    git clone https://github.com/urbainvaes/fzf-marks.git
    popd
    func_done
}

install_nerdfonts() {
    func_begin "Installing Nerd Fonts"

    wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip
    pushd ~/.local/share/fonts && unzip JetBrainsMono.zip && rm JetBrainsMono.zip && fc-cache -fv
    func_done
}

install_neovim() {
    func_begin "Installing Neovim"

    mkdir -p ~/dev/local-tools

    pushd ~/dev/local-tools
    git clone https://github.com/neovim/neovim.git --branch release-0.10

    pushd neovim
    sudo apt-get install -y ninja-build gettext cmake unzip curl build-essential
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
    popd # neovim

    popd # local-tools

    mkdir .virtualenvs
    pushd .virtualenvs
    virtualenv -p python3 neovim
    source neovim/bin/activate
    pip install --upgrade pip
    pip install neovim
    pip install pynvim
    popd # .virtualenvs

    # Install nvm and node 18.18.2
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh"

    nvm install 18.18.2
    nvm use 18.18.2
    npm install -g neovim

    pushd ~/dotfiles
    stow -v neovim-lua
    func_done
}

install_albert() {
    func_begin "Installing Albert"

    # Install albert
    echo 'deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_22.04/ /' | sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list
    curl -fsSL https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_22.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg > /dev/null
    sudo apt-get update
    sudo apt-get install -y albert

    pushd ~/dotfiles
    stow -v albert
    popd
    func_done
}


install_smartgit() {
    func_begin "Installing SmartGit"

    mkdir -p ~/Programs/smartgit
    pushd ~/Programs/smartgit
    filename=smartgit-linux-24_1_4
    wget https://download.smartgit.dev/smartgit/${filename}.tar.gz
    mkdir ${filename}
    tar -xvf ${filename}.tar.gz -C ${filename}
    rm ${filename}.tar.gz
    pushd ${filename}/smartgit/bin
    ./add-menuitem.sh
    popd # smartgit/bin
    popd # ~/Programs/smartgit/
    func_done
}

install_awesome() {
    func_begin "Installing Awesome WM"

    sudo apt-get install -y awesome build-essential gnome-flashback

    mkdir -p ~/dev/local-tools/
    pushd ~/dev/local-tools/
    git clone git@github.com:Stefantb/awesome-gnome.git
    pushd awesome-gnome
    sudo make install
    popd # awesome-gnome
    popd # local-tools

    pushd ~/dotfiles
    stow -v awesome

    gsettings set org.gnome.gnome-flashback desktop false
    gsettings set org.gnome.gnome-flashback root-background true
    func_done
}

install_kvm() {
    func_begin "Installing KVM and libvirt"

    sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
    # sudo adduser $USER libvirt
    # sudo adduser $USER kvm
    func_done
}

install_docker() {
    func_begin "Installing Docker"

    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # sudo groupadd docker
    sudo usermod -aG docker $USER


    cat <<EOF | sudo tee -a /etc/docker/daemon.json
{
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    },
    "bip": "172.26.0.1/16"
}
EOF
    sudo service docker restart
    func_done
}

install_uv_and_pipx() {
    func_begin "Installing uv and pipx"

    # Install luarocks and luarocks-magickwand
    curl -LsSf https://astral.sh/uv/install.sh | sh
    sudo apt-get install -y pipx
    func_done
}

install_vpn() {
    func_begin "Installing OpenConnect VPN"
    sudo apt-get install -y network-manager-openconnect \
        network-manager-openconnect-gnome \
        openconnect
    func_done
}

setup_git() {
    func_begin "Setting up git"
    pushd ~/dotfiles
    stow -v git
    git config --global user.name "Stefan Thor Bjarnason"
    git config --global user.email stefanb@tern.is
    git config --global alias.hop '!f() { git rev-parse --verify "$*" && git checkout "HEAD^{}" && git reset --soft "$*" && git checkout "$*"; }; f'
    func_done
}

install_vivaldi() {
    func_begin "Installing Vivaldi Browser"

    pushd ~
    wget https://downloads.vivaldi.com/stable/vivaldi-stable_7.5.3735.62-1_amd64.deb
    sudo apt install ./vivaldi-stable_7.5.3735.62-1_amd64.deb -y
    rm vivaldi-stable_7.5.3735.62-1_amd64.deb
    popd
    func_done
}

install_bob() {
    func_begin "Installing Bob"

    # Install build tools where they get mounted to the container
    pushd ~/dev/local-tools
    git clone git@github.com:Stefantb/build_tools.git
    git clone git@gitlab.com:TernDev/sandbox/stefanb/builders.git

    pushd build_tools
    stow -v -t ~/ bash_extensions/

    pushd bob_tool
    pipx install --editable .
    popd

    pushd header_tool
    pipx install --editable .
    popd

    pushd sort_includes_tool
    pipx install --editable .
    popd

    popd # build_tools
    popd # local-tools

    pushd ~/dotfiles
    stow -v bob-work

    func_done
}

install_basic_packages
install_dotfiles
install_bash_dotfiles
install_starship
install_fzf
install_nerdfonts
install_neovim
install_albert
install_smartgit
install_awesome
install_docker
install_uv_and_pipx
install_vpn
install_notes
install_vivaldi
install_bob

echo "All installations are complete!"
echo "Change hostname by running: sudo hostnamectl set-hostname <new-hostname>"
