#!/bin/bash

green_echo() {
    echo -e "\e[32m$1\e[0m"
}

NNN_BINARY_URL=https://github.com/jarun/nnn/releases/download/v5.0
NNN_BINARY_ARCHIVE=nnn-nerd-static-5.0.x86_64.tar.gz

green_echo "Starting system initialization..."


# Update and upgrade system packages
green_echo "Updating and upgrading system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential tools
ESSENTIAL_TOOLS=(
  zsh
  git
  tmux
)

green_echo "Installing essential tools: ${ESSENTIAL_TOOLS[*]}"
sudo apt install -y "${ESSENTIAL_TOOLS[@]}"

green_echo "Configuring tmux and installing plugins"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
mkdir -p ~/.config/tmux/
tmux source ~/.config/tmux/tmux.conf
~/.tmux/plugins/tpm/bin/install_plugins

green_echo "Setting zsh as the default shell"
chsh -s $(which zsh)

# Install development tools
DEV_TOOLS=(
  python3
  python3-pip
  openjdk-11-jdk
  nodejs
  npm
  docker.io
  docker-compose
)

# echo "Installing development tools: ${DEV_TOOLS[*]}"
# apt install -y "${DEV_TOOLS[@]}"

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

green_echo "Symlinking batcat to bat"
sudo ln -s /usr/bin/batcat /usr/bin/bat

green_echo "Installing nnn from static binary"
wget -P /tmp "${NNN_BINARY_URL}/${NNN_BINARY_ARCHIVE}"
tar -xzf /tmp/${NNN_BINARY_ARCHIVE} -C /tmp
mv /tmp/nnn-nerd-static /tmp/nnn
sudo mv /tmp/nnn /usr/local/bin/

green_echo "Downloading nnn plugins"
sh -c "$(curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs)"

green_echo "Installing zsh plugins and theme"
# mkdir -p ~/.zsh/powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.zsh/powerlevel10k

# mkdir -p ~/.zsh/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting

# mkdir -p ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions

# mkdir -p ~/.zsh/zsh-completions
git clone https://github.com/zsh-users/zsh-completions.git ~/.zsh/zsh-completions

# mkdir -p ~/.zsh/fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.zsh/fzf

~/.zsh/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-zsh --no-fish

# mkdir -p ~/.zsh/fzf-tab
git clone https://github.com/Aloxaf/fzf-tab ~/.zsh/fzf-tab


# Configure Git (Optional)
# echo "Configuring Git..."
# read -p "Enter your Git name: " GIT_NAME
# read -p "Enter your Git email: " GIT_EMAIL
# git config --global user.name "$GIT_NAME"
# git config --global user.email "$GIT_EMAIL"

# Clean up
echo "Cleaning up..."
sudo apt autoremove -y
sudo apt autoclean -y

green_echo "Initialization complete! Please reboot the system if necessary."
