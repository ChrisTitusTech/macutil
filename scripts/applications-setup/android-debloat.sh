#!/bin/sh -e

. ../common-script.sh

install_adb() {
    brew install android-platform-tools
}

install_universal_android_debloater() {
    if ! command_exists uad; then
        printf "%b\n" "${YELLOW}Installing Universal Android Debloater...${RC}."
        curl -sSLo "${HOME}/uad" "https://github.com/Universal-Debloater-Alliance/universal-android-debloater-next-generation/releases/latest/download/uad-ng-macos"
        "$ESCALATION_TOOL" chmod +x "${HOME}/uad"
        "$ESCALATION_TOOL" mv "${HOME}/uad" /usr/local/bin/uad
    else
        printf "%b\n" "${GREEN}Universal Android Debloater is already installed. Run 'uad' command to execute.${RC}"
    fi
}                   

checkEnv
install_adb
install_universal_android_debloater 
