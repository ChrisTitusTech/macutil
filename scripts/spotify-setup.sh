#!/bin/sh -e

. ../../common-script.sh

installSpotify() {
    if ! brewprogram_exists spotify; then
        printf "%b\n" "${YELLOW}Installing Spotify...${RC}"
        brew install --cask spotify
        if [ $? -ne 0 ]; then
            printf "%b\n" "${RED}Failed to install Spotify. Please check your Homebrew installation or try again later.${RC}"
            exit 1
        fi
        printf "%b\n" "${GREEN}Spotify installed successfully!${RC}"
    else
        printf "%b\n" "${GREEN}Spotify is already installed.${RC}"
    fi
}

checkEnv
installSpotify
