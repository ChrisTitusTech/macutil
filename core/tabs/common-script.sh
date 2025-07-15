#!/bin/sh -e

# shellcheck disable=SC2034

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
GREEN='\033[32m'

command_exists() {
for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || return 1
done
return 0
}

checkCommandRequirements() {
    ## Check for requirements.
    REQUIREMENTS=$1
    for req in ${REQUIREMENTS}; do
        if ! command_exists "${req}"; then
            printf "%b\n" "${RED}To run me, you need: ${REQUIREMENTS}${RC}"
            exit 1
        fi
    done
}

checkPackageManager() {
    ## Check if brew is installed
    if command -v brew >/dev/null 2>&1; then
        printf "%b\n" "${GREEN}Homebrew is already installed.${RC}"
        # Ensure Homebrew is in PATH for the current session
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f "/opt/homebrew/bin/brew" ]; then
        printf "%b\n" "${GREEN}Homebrew is installed but not in PATH. Adding to PATH...${RC}"
        # Add Homebrew to PATH and source it immediately
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        printf "%b\n" "${YELLOW}Homebrew is required but not installed. Installing Homebrew...${RC}"
        installHomebrew

        # Add Homebrew to PATH and source it immediately
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

installHomebrew() {
    ## Install Homebrew if not present
    printf "%b\n" "${CYAN}Downloading and installing Homebrew...${RC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Check if installation was successful by checking if the brew binary exists
    if [ -f "/opt/homebrew/bin/brew" ]; then
        printf "%b\n" "${GREEN}Homebrew installed successfully!${RC}"
    else
        printf "%b\n" "${RED}Homebrew installation failed. Please install manually.${RC}"
        printf "%b\n" "${YELLOW}Visit: https://brew.sh for manual installation instructions${RC}"
        exit 1
    fi
}

checkSuperUser() {
    ## Check SuperUser Group
    SUPERUSERGROUP='staff everyone admin'
    for sug in ${SUPERUSERGROUP}; do
        if groups | grep -q "${sug}"; then
            SUGROUP=${sug}
            printf "%b\n" "${CYAN}Super user group ${SUGROUP}${RC}"
            break
        fi
    done

    if command_exists "sudo"; then
        ESCALATION_TOOL="sudo"
    elif command_exists "doas"; then
        ESCALATION_TOOL="doas"
    else
        printf "%b\n" "${RED}You need to install either sudo or doas to run this script!${RC}"
        exit 1
    fi

    ## Check if member of the sudo group.
    if ! groups | grep -q "${SUGROUP}"; then
        printf "%b\n" "${RED}You need to be a member of the sudo group to run me!${RC}"
        exit 1
    fi
}

checkCurrentDirectoryWritable() {
    ## Check if the current directory is writable.
    GITPATH="$(dirname "$(realpath "$0")")"
    if [ ! -w "$GITPATH" ]; then
        printf "%b\n" "${RED}Can't write to $GITPATH${RC}"
        exit 1
    fi
}

checkEnv() {
    checkCommandRequirements "curl groups $ESCALATION_TOOL"
    checkPackageManager
    checkCurrentDirectoryWritable
    checkSuperUser
}
