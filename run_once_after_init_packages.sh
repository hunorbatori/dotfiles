#!/bin/bash

green_echo() {
    echo -e "\e[32m$1\e[0m"
}

# ---------------------------------------------------------------------------
# Detect the target OS/image
# ---------------------------------------------------------------------------
# Debian/Ubuntu: detected the same way as before.
# Bazzite: an immutable, rpm-ostree-based Fedora image. We match on "bazzite"
# anywhere in /etc/os-release rather than a single field, since ublue-based
# images have changed which field carries the name over time.
if grep -qiE "debian|ubuntu" /etc/os-release 2>/dev/null; then
    OS="debian"
elif grep -qi "bazzite" /etc/os-release 2>/dev/null; then
    OS="bazzite"
else
    echo "This script must be run on a Debian-based/Ubuntu system or on Bazzite."
    exit 0
fi

green_echo "Detected OS family: ${OS}"
green_echo "Starting system initialization..."

NNN_BINARY_URL=https://github.com/jarun/nnn/releases/download/v5.0
NNN_BINARY_ARCHIVE=nnn-nerd-static-5.0.x86_64.tar.gz

# ---------------------------------------------------------------------------
# Debian/Ubuntu branch — unchanged from the original script
# ---------------------------------------------------------------------------
install_debian_packages() {
    # Update and upgrade system packages
    green_echo "Updating and upgrading system packages..."
    sudo apt update && sudo apt upgrade -y

    # Install essential tools
    ESSENTIAL_TOOLS=(
        zsh
        git
        tmux
        xclip
        xsel
    )

    green_echo "Installing essential tools: ${ESSENTIAL_TOOLS[*]}"
    sudo apt install -y "${ESSENTIAL_TOOLS[@]}"

    # Install preferred utilities
    UTILITIES=(
        curl
        wget
        htop
        bat
        tree
        unzip
        file
        mediainfo
        tar
        man
    )

    green_echo "Installing utilities: ${UTILITIES[*]}"
    sudo apt install -y "${UTILITIES[@]}"

    if [ -L /usr/bin/bat ]; then
        green_echo "bat symlink already exists, skipping..."
    else
        green_echo "Symlinking batcat to bat"
        sudo ln -s /usr/bin/batcat /usr/bin/bat
    fi

    if command -v nnn &>/dev/null; then
        green_echo "nnn is already installed, skipping..."
    else
        green_echo "Installing nnn from static binary"
        wget -P /tmp "${NNN_BINARY_URL}/${NNN_BINARY_ARCHIVE}"
        tar -xzf /tmp/${NNN_BINARY_ARCHIVE} -C /tmp
        mv /tmp/nnn-nerd-static /tmp/nnn
        sudo mv /tmp/nnn /usr/local/bin/
    fi

    if command -v jump &>/dev/null; then
        green_echo "jump is already installed, skipping..."
    else
        green_echo "Downloading and installing jump"
        wget -P /tmp https://github.com/gsamokovarov/jump/releases/download/v0.51.0/jump_0.51.0_amd64.deb
        sudo dpkg -i /tmp/jump_0.51.0_amd64.deb
    fi
}

# ---------------------------------------------------------------------------
# Bazzite branch — same tool set, installed the Bazzite-appropriate way
# ---------------------------------------------------------------------------
# Bazzite is an immutable/atomic image (rpm-ostree). `rpm-ostree install` is
# only meant for system-level packages: it layers onto the image, needs a
# reboot to take effect, and can block future image updates until removed.
# For everyday CLI/TUI tools, Bazzite's own docs point to Homebrew instead,
# which installs into the user's home dir and needs no reboot.
install_bazzite_packages() {
    if ! command -v brew &>/dev/null; then
        green_echo "Homebrew not found, installing it first..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Make sure brew (and anything it installs later in this script) is on
    # PATH for the rest of this run, regardless of whether it was already
    # installed or shell rc files have picked it up yet.
    if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
        eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
    else
        eval "$(brew shellenv)"
    fi

    green_echo "Updating Homebrew..."
    brew update

    # Essential tools (same set as the Debian branch)
    ESSENTIAL_TOOLS=(
        zsh
        git
        tmux
        xclip
        xsel
    )

    green_echo "Installing essential tools: ${ESSENTIAL_TOOLS[*]}"
    brew install "${ESSENTIAL_TOOLS[@]}"

    # Utilities. curl, file, tar and man(-db) ship as part of Bazzite's base
    # image already, so there's nothing to install for those.
    UTILITIES=(
        wget
        htop
        bat
        tree
        unzip
        mediainfo
    )

    green_echo "Installing utilities: ${UTILITIES[*]}"
    brew install "${UTILITIES[@]}"

    # No batcat->bat symlink needed: Homebrew's bat formula installs the
    # binary as `bat` directly (that naming clash is Debian-specific).

    if command -v nnn &>/dev/null; then
        green_echo "nnn is already installed, skipping..."
    else
        green_echo "Installing nnn via Homebrew"
        brew install nnn
    fi

    if command -v jump &>/dev/null; then
        green_echo "jump is already installed, skipping..."
    else
        green_echo "Installing jump via Homebrew"
        brew install jump
    fi
}

# ---------------------------------------------------------------------------
# Shared setup — distro-agnostic, just needs git/tmux/zsh to already exist
# ---------------------------------------------------------------------------
setup_tmux_plugins() {
    if [ -d ~/.tmux/plugins/tpm/.git ]; then
        green_echo "TPM is already installed, skipping..."
    else
        green_echo "Configuring tmux and installing plugins"
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        mkdir -p ~/.config/tmux/
        tmux source ~/.config/tmux/tmux.conf
        ~/.tmux/plugins/tpm/bin/install_plugins
    fi
}

set_default_shell_zsh() {
    local zsh_path
    zsh_path="$(command -v zsh)"

    if [ -z "$zsh_path" ]; then
        echo "zsh not found on PATH, skipping default-shell setup." >&2
        return
    fi

    # chsh requires the shell to be listed in /etc/shells. A distro-packaged
    # zsh (apt) is already listed; a Homebrew-installed zsh usually isn't,
    # so add it if needed. This is a no-op on the Debian branch.
    if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
        green_echo "Adding $zsh_path to /etc/shells"
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    if [ "$(basename "$SHELL")" != "zsh" ]; then
        if [ "$OS" = "bazzite" ]; then
            green_echo "Bazzite recommends setting the shell via your terminal emulator's profile. Skipping setting it as default shell"
        else
            green_echo "Setting zsh as the default shell"
            chsh -s "$zsh_path"
	fi
    else
        green_echo "Default shell is already zsh, skipping..."
    fi
}

install_zsh_plugins() {
    green_echo "Installing zsh plugins and theme"

    if [ -d ~/.zsh/powerlevel10k/.git ]; then
        green_echo "pl10k is already cloned, skipping..."
    else
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.zsh/powerlevel10k
    fi

    if [ -d ~/.zsh/zsh-syntax-highlighting/.git ]; then
        green_echo "zsh-syntax-highlighting is already cloned, skipping..."
    else
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
    fi

    if [ -d ~/.zsh/zsh-autosuggestions/.git ]; then
        green_echo "zsh-autosuggestions is already cloned, skipping..."
    else
        git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    fi

    if [ -d ~/.zsh/zsh-completions/.git ]; then
        green_echo "zsh-completions is already cloned, skipping..."
    else
        git clone https://github.com/zsh-users/zsh-completions.git ~/.zsh/zsh-completions
    fi

    if [ -d ~/.zsh/fzf-tab/.git ]; then
        green_echo "fzf-tab is already cloned, skipping..."
    else
        git clone https://github.com/Aloxaf/fzf-tab ~/.zsh/fzf-tab
    fi

    if [ -d ~/.zsh/fzf/.git ]; then
        green_echo "fzf is already cloned, skipping..."
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.zsh/fzf
        ~/.zsh/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-zsh --no-fish
    fi
}

install_nnn_plugins() {
    if [ -d ~/.config/nnn/plugins ]; then
        green_echo "nnn plugins already exist, skipping..."
    else
        green_echo "Downloading nnn plugins"
        sh -c "$(curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs)"
    fi
}

cleanup() {
    green_echo "Cleaning up..."
    if [ "$OS" = "debian" ]; then
        sudo apt autoremove -y
        sudo apt autoclean -y
    else
        brew cleanup
    fi
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
if [ "$OS" = "debian" ]; then
    install_debian_packages
elif [ "$OS" = "bazzite" ]; then
    install_bazzite_packages
fi

setup_tmux_plugins
set_default_shell_zsh
install_nnn_plugins
install_zsh_plugins
cleanup

green_echo "Initialization complete! Please reboot the system if necessary."
