#!/bin/sh -e

. ../common-script.sh

fixfinder () {
    printf "%b\n" "${YELLOW}Applying global theme settings for Finder...${RC}"

    # Set the default Finder view to list view
    printf "%b\n" "${CYAN}Setting default Finder view to list view...${RC}"
    $ESCALATION_TOOL defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    
    # Configure list view settings for all folders
    printf "%b\n" "${CYAN}Configuring list view settings for all folders...${RC}"
    # Set default list view settings for new folders
    $ESCALATION_TOOL defaults write com.apple.finder FK_StandardViewSettings -dict-add ListViewSettings '{ "columns" = ( { "ascending" = 1; "identifier" = "name"; "visible" = 1; "width" = 300; }, { "ascending" = 0; "identifier" = "dateModified"; "visible" = 1; "width" = 181; }, { "ascending" = 0; "identifier" = "size"; "visible" = 1; "width" = 97; } ); "iconSize" = 16; "showIconPreview" = 0; "sortColumn" = "name"; "textSize" = 12; "useRelativeDates" = 1; }'
    
    # Clear existing folder view settings to force use of default settings
    printf "%b\n" "${CYAN}Clearing existing folder view settings...${RC}"
    $ESCALATION_TOOL defaults delete com.apple.finder FXInfoPanesExpanded 2>/dev/null || true
    $ESCALATION_TOOL defaults delete com.apple.finder FXDesktopVolumePositions 2>/dev/null || true
    
    # Set list view for all view types
    printf "%b\n" "${CYAN}Setting list view for all folder types...${RC}"
    $ESCALATION_TOOL defaults write com.apple.finder FK_StandardViewSettings -dict-add ExtendedListViewSettings '{ "columns" = ( { "ascending" = 1; "identifier" = "name"; "visible" = 1; "width" = 300; }, { "ascending" = 0; "identifier" = "dateModified"; "visible" = 1; "width" = 181; }, { "ascending" = 0; "identifier" = "size"; "visible" = 1; "width" = 97; } ); "iconSize" = 16; "showIconPreview" = 0; "sortColumn" = "name"; "textSize" = 12; "useRelativeDates" = 1; }'
    
    # Sets default search scope to the current folder
    printf "%b\n" "${CYAN}Setting default search scope to the current folder...${RC}"
    $ESCALATION_TOOL defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

    # Remove trash items older than 30 days
    printf "%b\n" "${CYAN}Removing trash items older than 30 days...${RC}"
    $ESCALATION_TOOL defaults write com.apple.finder "FXRemoveOldTrashItems" -bool "true"

    # Remove .DS_Store files to reset folder view settings
    printf "%b\n" "${CYAN}Removing .DS_Store files to reset folder view settings...${RC}"
    find ~ -name ".DS_Store" -type f -delete 2>/dev/null || true

    # Show all filename extensions
    printf "%b\n" "${CYAN}Showing all filename extensions in Finder...${RC}"
    $ESCALATION_TOOL defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    # Show status bar in Finder
    printf "%b\n" "${CYAN}Showing status bar in Finder...${RC}"
    $ESCALATION_TOOL defaults write com.apple.finder ShowStatusBar -bool true

    # Show path bar in Finder
    printf "%b\n" "${CYAN}Showing path bar in Finder...${RC}"
    $ESCALATION_TOOL defaults write com.apple.finder ShowPathbar -bool true

    # Clean up Finder's sidebar
    printf "%b\n" "${CYAN}Cleaning up Finder's sidebar...${RC}"
    $ESCALATION_TOOL defaults write com.apple.finder SidebarDevicesSectionDisclosedState -bool true
    $ESCALATION_TOOL defaults write com.apple.finder SidebarPlacesSectionDisclosedState -bool true
    
    # Restart Finder to apply changes
    printf "%b\n" "${GREEN}Finder has been restarted and settings have been applied.${RC}"
    $ESCALATION_TOOL killall Finder
}

checkEnv
fixfinder
