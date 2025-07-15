#!/bin/sh -e

. ../common-script.sh

cleanup_system() {
    printf "%b\n" "${YELLOW}Performing macOS system cleanup...${RC}"
    
    # Clean Homebrew cache and remove old versions
    if command_exists "brew"; then
        printf "%b\n" "${CYAN}Cleaning Homebrew cache and removing old versions...${RC}"
        brew cleanup
        brew autoremove
        brew doctor
    fi
    
    # Clean macOS system caches
    printf "%b\n" "${CYAN}Cleaning macOS system caches...${RC}"
    "$ESCALATION_TOOL" find /Library/Caches -type f -delete 2>/dev/null || true
    "$ESCALATION_TOOL" find /System/Library/Caches -type f -delete 2>/dev/null || true
    
    # Clean user caches
    printf "%b\n" "${CYAN}Cleaning user caches...${RC}"
    find ~/Library/Caches -type f -delete 2>/dev/null || true
    find ~/Library/Application\ Support/Caches -type f -delete 2>/dev/null || true
    
    # Clean Xcode derived data (if Xcode is installed)
    if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
        printf "%b\n" "${CYAN}Cleaning Xcode derived data...${RC}"
        rm -rf ~/Library/Developer/Xcode/DerivedData/*
    fi
    
    # Clean iOS Simulator caches (if Xcode is installed)
    if [ -d ~/Library/Developer/CoreSimulator ]; then
        printf "%b\n" "${CYAN}Cleaning iOS Simulator caches...${RC}"
        rm -rf ~/Library/Developer/CoreSimulator/Devices/*/data/var/mobile/Media/DCIM/*
        rm -rf ~/Library/Developer/CoreSimulator/Devices/*/data/var/mobile/Media/PhotoData/*
    fi
}

common_cleanup() {
    printf "%b\n" "${CYAN}Performing common cleanup tasks...${RC}"
    
    # Clean temporary files
    if [ -d /tmp ]; then
        "$ESCALATION_TOOL" find /tmp -type f -atime +5 -delete 2>/dev/null || true
    fi
    
    if [ -d /var/tmp ]; then
        "$ESCALATION_TOOL" find /var/tmp -type f -atime +5 -delete 2>/dev/null || true
    fi
    
    # Clean system logs (keep last 3 days)
    if [ "$ESCALATION_TOOL" = "sudo" ]; then
        printf "%b\n" "${CYAN}Cleaning old system logs...${RC}"
        # Remove logs older than 7 days
        "$ESCALATION_TOOL" find /var/log -name "*.log.*" -mtime +7 -delete 2>/dev/null || true
        "$ESCALATION_TOOL" find /var/log -name "*.out.*" -mtime +7 -delete 2>/dev/null || true
        # Clean system log archives older than 30 days
        "$ESCALATION_TOOL" find /var/log -name "*.gz" -mtime +30 -delete 2>/dev/null || true
    fi
    
    # Clean DNS cache
    printf "%b\n" "${CYAN}Flushing DNS cache...${RC}"
    "$ESCALATION_TOOL" dscacheutil -flushcache
    "$ESCALATION_TOOL" killall -HUP mDNSResponder
    
    # Clean font caches (only on macOS < 14)
    if [ "$(sw_vers -productVersion | cut -d. -f1)" -lt 14 ]; then
        printf "%b\n" "${CYAN}Cleaning font caches...${RC}"
        "$ESCALATION_TOOL" atsutil databases -remove 2>/dev/null || true
        "$ESCALATION_TOOL" atsutil server -shutdown 2>/dev/null || true
        "$ESCALATION_TOOL" atsutil server -ping 2>/dev/null || true
    else
        printf "%b\n" "${CYAN}Skipping font cache cleanup (ATS not supported in macOS 14+)${RC}"
    fi
}

clean_data() {
    printf "%b" "${YELLOW}Clean up old cache files and empty the trash? (y/N): ${RC}"
    read -r clean_response
    case $clean_response in
        y|Y)
            printf "%b\n" "${YELLOW}Cleaning up old cache files and emptying trash...${RC}"
            
            # Clean user cache directories
            if [ -d "$HOME/.cache" ]; then
                find "$HOME/.cache/" -type f -atime +5 -delete 2>/dev/null || true
            fi
            
            # Clean various application caches
            if [ -d "$HOME/Library/Application Support" ]; then
                find "$HOME/Library/Application Support" -name "Cache" -type d -exec rm -rf {} + 2>/dev/null || true
            fi
            
            # Clean browser caches
            if [ -d "$HOME/Library/Safari" ]; then
                rm -rf "$HOME/Library/Safari/WebpageIcons.db" 2>/dev/null || true
                rm -rf "$HOME/Library/Safari/LocalStorage" 2>/dev/null || true
            fi
            
            if [ -d "$HOME/Library/Application Support/Google/Chrome" ]; then
                rm -rf "$HOME/Library/Application Support/Google/Chrome/Default/Cache" 2>/dev/null || true
            fi
            
            if [ -d "$HOME/Library/Application Support/Firefox" ]; then
                rm -rf "$HOME/Library/Application Support/Firefox/Profiles/*/cache2" 2>/dev/null || true
            fi
            
            # Empty trash
            printf "%b\n" "${CYAN}Emptying trash...${RC}"
            rm -rf ~/.Trash/* 2>/dev/null || true
            
            # Clean downloads folder (files older than 30 days)
            if [ -d "$HOME/Downloads" ]; then
                printf "%b\n" "${CYAN}Cleaning old downloads (older than 30 days)...${RC}"
                find "$HOME/Downloads" -type f -atime +30 -delete 2>/dev/null || true
            fi
            
            printf "%b\n" "${GREEN}Cache and trash cleanup completed.${RC}"
            ;;
        *)
            printf "%b\n" "${YELLOW}Skipping cache and trash cleanup.${RC}"
            ;;
    esac
}

clean_docker() {
    if command_exists "docker"; then
        printf "%b" "${YELLOW}Clean up Docker system (containers, images, volumes)? (y/N): ${RC}"
        read -r docker_response
        case $docker_response in
            y|Y)
                printf "%b\n" "${CYAN}Cleaning Docker system...${RC}"
                docker system prune -a -f --volumes
                printf "%b\n" "${GREEN}Docker cleanup completed.${RC}"
                ;;
            *)
                printf "%b\n" "${YELLOW}Skipping Docker cleanup.${RC}"
                ;;
        esac
    fi
}

clean_node_modules() {
    printf "%b" "${YELLOW}Clean up node_modules directories (older than 30 days)? (y/N): ${RC}"
    read -r node_response
    case $node_response in
        y|Y)
            printf "%b\n" "${CYAN}Cleaning old node_modules directories...${RC}"
            find "$HOME" -name "node_modules" -type d -atime +30 -exec rm -rf {} + 2>/dev/null || true
            printf "%b\n" "${GREEN}Node modules cleanup completed.${RC}"
            ;;
        *)
            printf "%b\n" "${YELLOW}Skipping node_modules cleanup.${RC}"
            ;;
    esac
}

system_cleanup() {
    printf "%b\n" "${YELLOW}Performing comprehensive macOS system cleanup...${RC}"
    
    cleanup_system
    common_cleanup
    clean_data
    clean_docker
    clean_node_modules
    
    printf "%b\n" "${GREEN}macOS system cleanup completed!${RC}"
}

checkEnv
system_cleanup
