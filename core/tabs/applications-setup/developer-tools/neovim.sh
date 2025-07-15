#!/bin/sh -e

. ../../common-script.sh

installNeovim() {
    printf "%b\n" "${YELLOW}Setting up Neovim...${RC}"
    
    # Install Neovim and dependencies with brew
    printf "%b\n" "${CYAN}Installing Neovim and dependencies...${RC}"
    brew install neovim ripgrep fzf
    
    # Backup existing config if it exists
    if [ -d "$HOME/.config/nvim" ] && [ ! -d "$HOME/.config/nvim-backup" ]; then
        printf "%b\n" "${YELLOW}Backing up existing Neovim config...${RC}"
        cp -r "$HOME/.config/nvim" "$HOME/.config/nvim-backup"
    fi
    
    # Clear existing config
    rm -rf "$HOME/.config/nvim"
    mkdir -p "$HOME/.config/nvim"
    
    # Clone Titus kickstart config directly to .config/nvim
    printf "%b\n" "${CYAN}Applying Titus Kickstart config...${RC}"
    git clone --depth 1 https://github.com/ChrisTitusTech/neovim.git /tmp/neovim
    cp -r /tmp/neovim/titus-kickstart/* "$HOME/.config/nvim/"
    rm -rf /tmp/neovim
    printf "%b\n" "${GREEN}Neovim setup completed.${RC}"
}

checkEnv
installNeovim