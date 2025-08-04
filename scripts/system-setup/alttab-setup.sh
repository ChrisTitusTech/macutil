#!/bin/sh -e

# shellcheck source=../common-script.sh
. ../common-script.sh

installAltTab() {
    if ! brewprogram_exists alt-tab; then
        printf "%b\n" "${YELLOW}Installing AltTab...${RC}"
        if ! brew install --cask alt-tab; then
            printf "%b\n" "${RED}Failed to install AltTab. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}AltTab installed successfully!${RC}"
        
        # Configure AltTab for optimal experience
        configureAltTab
    else
        printf "%b\n" "${GREEN}AltTab is already installed.${RC}"
        printf "%b\n" "${YELLOW}Applying configuration...${RC}"
        configureAltTab
    fi
}

configureAltTab() {
    printf "%b\n" "${YELLOW}Configuring AltTab preferences...${RC}"
    
    # Kill AltTab if it's running to ensure clean configuration
    pkill -f "AltTab" 2>/dev/null || true
    
    # Wait a moment for the process to terminate
    sleep 1
    
    # Show hidden windows
    defaults write com.lwouis.alt-tab-macos showHiddenWindows -bool true
    
    # Overwrite the default hold shortcut to Cmd (Windows-like behavior)
    defaults write com.lwouis.alt-tab-macos holdShortcut -string "⌘"
    
    # Enable start at login
    defaults write com.lwouis.alt-tab-macos startAtLogin -bool true
    
    # Start AltTab silently in the background to initialize settings
    open -g -a "AltTab" 2>/dev/null || true
    
    printf "%b\n" "${GREEN}AltTab configuration applied successfully!${RC}"
    printf "%b\n" "${CYAN}Note: You may need to grant AltTab accessibility permissions in System Settings > Privacy & Security > Accessibility${RC}"
}

checkEnv
installAltTab

printf "%b\n" "${GREEN}AltTab setup completed!${RC}"
printf "%b\n" "${CYAN}You can now use Cmd+Tab to switch between individual windows (Windows-like behavior)${RC}"
printf "%b\n" "${CYAN}AltTab will start automatically on your next login.${RC}"
printf "%b\n" "${CYAN}To configure further options or start it now, find AltTab in your Applications folder.${RC}"
