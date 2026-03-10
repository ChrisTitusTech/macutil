#!/bin/sh -e

. ../../common-script.sh

installProtonDrive() {
    if ! brewprogram_exists proton-drive; then
        printf "%b\n" "${YELLOW}Installing Proton Drive...${RC}"
        brew install --cask proton-drive > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Proton Drive. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Proton Drive installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Proton Drive is already installed.${RC}"
    fi
}

checkEnv
installProtonDrive
