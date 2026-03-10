#!/bin/sh -e

. ../../common-script.sh

install_appcleaner() {
    if ! brewprogram_exists appcleaner; then
        printf "%b\n" "${YELLOW}Installing AppCleaner...${RC}"
        brew install --cask appcleaner
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install AppCleaner. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}AppCleaner installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}AppCleaner is already installed.${RC}"
    fi
}

checkEnv
install_appcleaner
