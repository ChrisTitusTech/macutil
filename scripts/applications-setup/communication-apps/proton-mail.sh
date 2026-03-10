#!/bin/sh -e

. ../../common-script.sh

installProtonMail() {
    if ! brewprogram_exists proton-mail; then
        printf "%b\n" "${YELLOW}Installing Proton Mail...${RC}"
        brew install --cask proton-mail > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Proton Mail. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Proton Mail installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Proton Mail is already installed.${RC}"
    fi
}

checkEnv
installProtonMail
