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

if [ -d "~/.tmux/plugins/tpm/.git" ]; then
	green_echo "TPM is already installed, skipping..."
else
	green_echo "Configuring tmux and installing plugins"
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	mkdir -p ~/.config/tmux/
	tmux source ~/.config/tmux/tmux.conf
	~/.tmux/plugins/tpm/bin/install_plugins
fi

if [ "$(basename "$SHELL")" != "zsh" ]; then
	green_echo "Setting zsh as the default shell"
	chsh -s $(which zsh)
else
	green_echo "Default shell is already zsh, skipping..."
fi



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

if [ -L " /usr/bin/bat" ]; then
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

if [ -d "~/.config/nnn/plugins" ]; then
	green_echo "nnn plugins already existm, skipping..."
else
	green_echo "Downloading nnn plugins"
	sh -c "$(curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs)"
fi

green_echo "Installing zsh plugins and theme"

if [ -d "~/.zsh/powerlevel10k/.git" ]; then
	green_echo "pl10k is already cloned, skipping..."
else
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.zsh/powerlevel10k
fi

if [ -d "~/.zsh/zsh-syntax-highlighting/.git" ]; then
        green_echo "zsh-syntax-highlighting is already cloned, skipping..."
else
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
fi

if [ -d "~/.zsh/zsh-autosuggestions/.git" ]; then
        green_echo "zsh-autosuggestions is already cloned, skipping..."
else
	git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
fi

if [ -d "~/.zsh/zsh-completions/.git" ]; then
        green_echo "zsh-completions is already cloned, skipping..."
else
	git clone https://github.com/zsh-users/zsh-completions.git ~/.zsh/zsh-completions
fi

if [ -d "~/.zsh/fzf-tab/.git" ]; then
        green_echo "fzf-tab is already cloned, skipping..."
else
	git clone https://github.com/Aloxaf/fzf-tab ~/.zsh/fzf-tab
fi

if [ -d "~/.zsh/fzf/.git" ]; then
        green_echo "fzf is already cloned, skipping..."
else
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.zsh/fzf
	~/.zsh/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-zsh --no-fish
fi

# Clean up
green_echo "Cleaning up..."
sudo apt autoremove -y
sudo apt autoclean -y

green_echo "Initialization complete! Please reboot the system if necessary."
