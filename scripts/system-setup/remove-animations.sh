#!/bin/sh -e

. ../common-script.sh

removeAnimations() {
    printf "%b\n" "${YELLOW}Reducing motion and animations on macOS...${RC}"
    
    # Reduce motion in Accessibility settings (most effective)
    printf "%b\n" "${CYAN}Setting reduce motion preference...${RC}"
    $ESCALATION_TOOL defaults write com.apple.universalaccess reduceMotion -bool true
    
    # Disable window animations
    printf "%b\n" "${CYAN}Disabling window animations...${RC}"
    $ESCALATION_TOOL defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
    
    # Speed up window resize animations
    printf "%b\n" "${CYAN}Speeding up window resize animations...${RC}"
    $ESCALATION_TOOL defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
    
    # Disable smooth scrolling
    printf "%b\n" "${CYAN}Disabling smooth scrolling...${RC}"
    $ESCALATION_TOOL defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false
    
    # Disable animation when opening and closing windows
    printf "%b\n" "${CYAN}Disabling window open/close animations...${RC}"
    $ESCALATION_TOOL defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
    
    # Disable animation when opening a Quick Look window
    printf "%b\n" "${CYAN}Disabling Quick Look animations...${RC}"
    $ESCALATION_TOOL defaults write -g QLPanelAnimationDuration -float 0
    
    # Disable animation when opening the Info window in Finder
    printf "%b\n" "${CYAN}Disabling Finder Info window animations...${RC}"
    $ESCALATION_TOOL defaults write com.apple.finder DisableAllAnimations -bool true
    
    # Speed up Mission Control animations
    printf "%b\n" "${CYAN}Speeding up Mission Control animations...${RC}"
    $ESCALATION_TOOL defaults write com.apple.dock expose-animation-duration -float 0.1
    $ESCALATION_TOOL defaults write com.apple.dock expose-group-apps -bool true

    # Speed up Launchpad animations
    printf "%b\n" "${CYAN}Speeding up Launchpad animations...${RC}"
    $ESCALATION_TOOL defaults write com.apple.dock springboard-show-duration -float 0.1
    $ESCALATION_TOOL defaults write com.apple.dock springboard-hide-duration -float 0.1
    
    # Disable dock hiding animation
    printf "%b\n" "${CYAN}Disabling dock hiding animations...${RC}"
    $ESCALATION_TOOL defaults write com.apple.dock autohide-time-modifier -float 0
    $ESCALATION_TOOL defaults write com.apple.dock autohide-delay -float 0
    
    # Disable animations in Mail.app
    printf "%b\n" "${CYAN}Disabling Mail animations...${RC}"
    $ESCALATION_TOOL defaults write com.apple.mail DisableReplyAnimations -bool true
    $ESCALATION_TOOL defaults write com.apple.mail DisableSendAnimations -bool true
    
    # Disable zoom animation when focusing on text input fields
    printf "%b\n" "${CYAN}Disabling text field zoom animations...${RC}"
    $ESCALATION_TOOL defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true
    
    printf "%b\n" "${GREEN}Motion and animations have been reduced.${RC}"
    $ESCALATION_TOOL killall Dock
    printf "%b\n" "${YELLOW}Dock Restarted.${RC}"
}

checkEnv
removeAnimations