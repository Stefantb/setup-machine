#!/bin/bash

# Sets up on a new machine with Pop!_OS 22.04

install_basic_packages() {
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
}

install_starship() {
    # Install starship
    curl -sS https://starship.rs/install.sh | sh

    pushd ~/dotfiles
    stow -v starship
}

install_bash_dotfiles() {
    # Install bash dotfiles
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

    pushd ~/dotfiles
    stow -v bash
}


install_dotfiles() {
    # Clone the dotfiles repository
    pushd ~
    git clone --recurse-submodules -j8 git@github.com:Stefantb/dotfiles.git

    # Maks sure to create some directories to prevent stow from taking ownership
    mkdir -p .local/bin

    pushd dotfiles
    # Use stow to symlink the dotfiles
    stow -v kitty
    stow -v ranger
    stow -v git
    sudo stow -v -t / system_commands
    popd

    install_bash_dotfiles
}


setup_notes() {
    pushd ~/dev/
    git clone git@github.com:Stefantb/notes.git

    pushd ~/dotfiles
    ./setup-notes-git-sync.sh
}


install_fzf() {
    # Install fzf
    pushd ~
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
    mkdir -p dev/local-tools/
    pushd dev/local-tools
    git clone https://github.com/urbainvaes/fzf-marks.git
}


setup_neovim() {
    pushd ~
    mkdir -p dev/local-tools

    pushd dev/local-tools
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

    install_fzf

    # Install nvm and node 18.18.2
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    NVM_DIR="$HOME/.nvm"
    source "$NVM_DIR/nvm.sh"

    nvm install 18.18.2
    nvm use 18.18.2
    npm install -g neovim

    pushd ~/dotfiles
    stow -v neovim-lua
}

install_albert() {
    # Install albert
    echo 'deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_22.04/ /' | sudo tee /etc/apt/sources.list.d/home:manuelschneid3r.list
    curl -fsSL https://download.opensuse.org/repositories/home:manuelschneid3r/xUbuntu_22.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_manuelschneid3r.gpg > /dev/null
    sudo apt-get update
    sudo apt-get install -y albert

    pushd ~/dotfiles
    stow -v albert
}


install_smartgit() {
    pushd ~
    mkdir -p Programs/smartgit
    pushd Programs/smartgit
    filename=smartgit-linux-24_1_4
    wget https://download.smartgit.dev/smartgit/${filename}.tar.gz
    mkdir ${filename}
    tar -xvf ${filename}.tar.gz -C ${filename}
    rm ${filename}.tar.gz

    pushd ${filename}/smartgit/bin
    ./add-menuitem.sh
}

install_awesome() {

    sudo apt-get install -y awesome build-essential gnome-flashback

    mkdir -p ~/dev/local-tools/
    pushd ~/dev/local-tools/
    git clone git@github.com:Stefantb/awesome-gnome.git
    pushd awesome-gnome
    sudo make install

    gsettings set org.gnome.gnome-flashback desktop false
    gsettings set org.gnome.gnome-flashback root-background true
}

install_kvm() {
    sudo apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
    # sudo adduser $USER libvirt
    # sudo adduser $USER kvm
}

install_docker() {
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
}

install_uv_and_pipx() {
    # Install luarocks and luarocks-magickwand
    curl -LsSf https://astral.sh/uv/install.sh | sh
    sudo apt-get install -y pipx
}

install_vpn() {
    sudo apt-get install -y network-manager-openconnect \
        network-manager-openconnect-gnome \
        openconnect
}

setup_git() {
    git config --global alias.hop '!f() { git rev-parse --verify "$*" && git checkout "HEAD^{}" && git reset --soft "$*" && git checkout "$*"; }; f'
}

install_basic_packages
install_dotfiles
install_bash_dotfiles
install_starship
setup_neovim
install_albert
install_smartgit
install_awesome
install_docker
install_uv_and_pipx
install_vpn
setup_notes

