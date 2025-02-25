#!/bin/bash
set -e # Exit script immediately on first error.

# Create log file with timestamp and redirect stdout and stderr to it
LOGFILE="logs/install-$(date +"%Y-%m-%d_%H-%M-%S").log"
mkdir -p logs
touch "$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1

# Generate SSH key pair
# check if ssh key exists, if not generate one
if [ -f ~/.ssh/id_ed25519 ]; then
    echo "SSH key already exists."
else
    echo "Generating SSH key..."
    read -p "Enter a comment for your SSH key (Git Email): " key_comment
    ssh-keygen -t ed25519 -C "$key_comment"
fi

# Eza install
# Check if Eza repository is already added
if [ -f /etc/apt/sources.list.d/gierens.list ]; then
    echo "Eza repository already added."
else
    echo "Adding Eza repository..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
fi

# Fastfetch install
# Check if Fastfetch repository is already added
if [ -f /etc/apt/sources.list.d/zhangsongcui3371-ubuntu-fastfetch-noble.sources ]; then
    echo "Fastfetch repository already added."
else
    echo "Adding Fastfetch repository..."
    sudo add-apt-repository ppa:zhangsongcui3371/fastfetch -y
fi

# Update and upgrade
echo "Starting system update and upgrade..."
sudo apt update -y && sudo apt upgrade -y
# Essential packages
sudo apt install -y git curl wget zsh vim tmux htop build-essential make cmake \
    python3-dev python3-pip python3-setuptools python3-venv python-is-python3 fzf pipx gpg eza fastfetch

# Poetry install
echo "Installing Poetry via pipx..."
pipx install poetry

# Zoxide
# Check if Zoxide is already installed
if [ -f /usr/local/bin/zoxide ] || [ -f $HOME/.local/bin/zoxide ]; then
    echo "Zoxide already installed."
else
    echo "Installing Zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# Install Oh My Zsh
# Check if Oh My Zsh is already installed
if [ -d ~/.oh-my-zsh ]; then
    echo "Oh My Zsh already installed."
else
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" -s --batch || {
        echo "Could not install Oh My Zsh" >/dev/stderr
        exit 1
    }
fi

# Zsh Plugins
# Check if Zsh plugins are already installed
# check if ZSH_CUSTOM is not empty
if [ -z "$ZSH_CUSTOM" ]; then
    echo "ZSH_CUSTOM is empty. Setting ZSH_CUSTOM to ~/.oh-my-zsh/custom..."
    ZSH_CUSTOM=~/.oh-my-zsh/custom
fi

echo "Installing Zsh plugins..."
if [ -d $ZSH_CUSTOM/plugins/zsh-autosuggestions ]; then
    echo "Zsh Autosuggestion already installed."
else
    echo "Installing Zsh Autosuggestion..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
fi

if [ -d $ZSH_CUSTOM/plugins/zsh-autocomplete ]; then
    echo "Zsh Autocomplete already installed."
else
    echo "Installing Zsh Autocomplete..."
    git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git $ZSH_CUSTOM/plugins/zsh-autocomplete 
fi

if [ -d $ZSH_CUSTOM/plugins/zsh-syntax-highlighting ]; then 
    echo "Zsh Syntax Highlighting already installed."
else
    echo "Installing Zsh Syntax Highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
fi

if [ -d $ZSH_CUSTOM/plugins/F-Sy-H ]; then 
    echo "F-Sy-H already installed."
else
    echo "Installing F-Sy-H..."
    git clone https://github.com/z-shell/F-Sy-H.git \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/F-Sy-H
fi

# Copy configuration files (back up if they exist)
echo "Copying configuration files..."
for file in .aliases .zshrc; do
    if [ -f ~/"$file" ]; then
        echo "Backing up existing $file to ${file}.bak"
        mv ~/"$file" ~/"${file}.bak"
    fi
    echo "Copying $file to home directory..."
    cp "$file" ~/"$file"
done

# Copy .config in home directory without overwriting existing files
echo "Copying .config files..."
mkdir -p ~/.config
cp -rn .config/* ~/.config/

# Change shell to zsh
echo "Changing shell to zsh..."
chsh -s $(which zsh)

# Install p10k
# Check if Powerlevel10k is already installed
if [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    echo "Powerlevel10k already installed."
else
    echo "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
fi

# Restart shell
exec zsh

# Start p10k configuration
echo "Launching Powerlevel10k configuration..."
p10k configure

echo "Installation completed successfully."