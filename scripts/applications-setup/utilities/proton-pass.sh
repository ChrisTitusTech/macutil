#!/bin/sh -e

. ../../common-script.sh

installProtonPass() {
    if ! brewprogram_exists proton-pass; then
        printf "%b\n" "${YELLOW}Installing Proton Pass...${RC}"
        brew install --cask proton-pass > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Proton Pass. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Proton Pass installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Proton Pass is already installed.${RC}"
    fi
}

checkEnv
installProtonPass
