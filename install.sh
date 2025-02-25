#!/bin/bash
set -e # Exit script immediately on first error.

# Create log file with timestamp and redirect stdout and stderr to it
LOGFILE="logs/install-$(date +"%Y-%m-%d_%H-%M-%S").log"
mkdir -p logs
touch "$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1

# Generate SSH key pair
read -p "Enter a comment for your SSH key: " key_comment
ssh-keygen -t ed25519 -C "$key_comment"

# Eza install
echo "Adding Eza repository..."
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

# Fastfetch install
echo "Adding Fastfetch"
sudo add-apt-repository ppa:zhangsongcui3371/fastfetch -y

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
echo "Installing Zoxide..."
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# Install Oh My Zsh
echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Zsh Plugins
echo "Installing Zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/z-shell/F-Sy-H.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/F-Sy-H

# Copy configuration files (back up if they exist)
echo "Copying configuration files..."
for file in .aliases .zshrc .zprofile; do
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

# Source .zshrc
echo "Sourcing .zshrc..."
source ~/.zshrc

# Install p10k
echo "Installing Powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# Start p10k configuration
echo "Launching Powerlevel10k configuration..."
p10k configure

echo "Installation completed successfully."