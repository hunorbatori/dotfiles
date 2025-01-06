#!/bin/bash

NNN_BINARY_URL=https://github.com/jarun/nnn/releases/download/v5.0
NNN_BINARY_ARCHIVE=nnn-nerd-static-5.0.x86_64.tar.gz

# Ensure the script runs as root or with sudo
if [[ "$EUID" -ne 0 ]]; then
  echo "Please run as root or use sudo."
  exit 1
fi

# Ensure the script uses the calling user's home directory
USER_HOME=$(eval echo "~$SUDO_USER")
cd "$USER_HOME"

echo "Starting system initialization..."

# Update and upgrade system packages
echo "Updating and upgrading system packages..."
apt update && apt upgrade -y

# Install essential tools
ESSENTIAL_TOOLS=(
  zsh
  git
  tmux
)

echo "Installing essential tools: ${ESSENTIAL_TOOLS[*]}"
apt install -y "${ESSENTIAL_TOOLS[@]}"

mkdir -p $USER_HOME/.config/tmux/
touch $USER_HOME/.config/tmux/tmux.conf
tmux source $USER_HOME/.config/tmux/tmux.conf

echo "Setting zsh as the default shell"
sudo chsh -s $(which zsh) "$SUDO_USER"

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

echo "Installing utilities: ${UTILITIES[*]}"
apt install -y "${UTILITIES[@]}"

echo "Symlinking batcat to bat"
ln -s /usr/bin/batcat /usr/bin/bat

echo "Installing nnn from static binary"
wget -P /tmp "${NNN_BINARY_URL}/${NNN_BINARY_ARCHIVE}"
tar -xzf /tmp/${NNN_BINARY_ARCHIVE} -C /tmp
mv /tmp/nnn-nerd-static /tmp/nnn
mv /tmp/nnn /usr/local/bin/

echo "Downloading nnn plugins"
sh -c "curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | HOME=/home/$SUDO_USER sh"


echo "Installing zsh plugins and theme"
# mkdir -p ~/.zsh/powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $USER_HOME/.zsh/powerlevel10k

# mkdir -p ~/.zsh/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $USER_HOME/.zsh/zsh-syntax-highlighting

# mkdir -p ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions $USER_HOME/.zsh/zsh-autosuggestions

# mkdir -p ~/.zsh/zsh-completions
git clone https://github.com/zsh-users/zsh-completions.git $USER_HOME/.zsh/zsh-completions

# mkdir -p ~/.zsh/fzf
git clone --depth 1 https://github.com/junegunn/fzf.git $USER_HOME/.zsh/fzf

$USER_HOME/.zsh/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-zsh --no-fish

# mkdir -p ~/.zsh/fzf-tab
git clone https://github.com/Aloxaf/fzf-tab $USER_HOME/.zsh/fzf-tab


# Configure Git (Optional)
# echo "Configuring Git..."
# read -p "Enter your Git name: " GIT_NAME
# read -p "Enter your Git email: " GIT_EMAIL
# git config --global user.name "$GIT_NAME"
# git config --global user.email "$GIT_EMAIL"

# Clean up
echo "Cleaning up..."
apt autoremove -y
apt autoclean -y

echo "Initialization complete! Please reboot the system if necessary."
