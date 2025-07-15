#!/bin/sh -e

. ../common-script.sh

updateHomebrew() {
    printf "%b\n" "${YELLOW}Updating Homebrew packages...${RC}"
    
    # Update Homebrew itself
    printf "%b\n" "${CYAN}Updating Homebrew...${RC}"
    brew update
    
    # Upgrade all installed packages
    printf "%b\n" "${CYAN}Upgrading installed packages...${RC}"
    brew upgrade
    
    # Clean up old versions and cache
    printf "%b\n" "${CYAN}Cleaning up old versions and cache...${RC}"
    brew cleanup
    brew autoremove
}

updateMacAppStore() {
    if command_exists "mas"; then
        printf "%b\n" "${YELLOW}Updating Mac App Store applications...${RC}"
        mas upgrade
    else
        printf "%b\n" "${YELLOW}Installing mas-cli for Mac App Store updates...${RC}"
        if brew install mas; then
            printf "%b\n" "${CYAN}Updating Mac App Store applications...${RC}"
            mas upgrade
        else
            printf "%b\n" "${RED}Failed to install mas-cli. Skipping Mac App Store updates.${RC}"
        fi
    fi
}

updateCasks() {
    printf "%b\n" "${YELLOW}Updating Homebrew Casks...${RC}"
    
    # Get list of outdated casks
    outdated_casks=$(brew outdated --cask 2>/dev/null)
    
    if [ -n "$outdated_casks" ]; then
        printf "%b\n" "${CYAN}Upgrading outdated casks...${RC}"
        brew upgrade --cask
    else
        printf "%b\n" "${GREEN}No outdated casks found.${RC}"
    fi
}

printf "%b\n" "${GREEN}System update completed!${RC}"

checkEnv
updateHomebrew
updateCasks
updateMacAppStore