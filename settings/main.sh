#! /usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

export PI_BOOT_ROOT="/Volumes/bootfs"
export PI_CLI="${PI_CLI:-/Applications/Raspberry Pi Imager.app/Contents/MacOS/rpi-imager}"
export PI_INTEGRITY="${PI_INTEGRITY:-d2a54d6a13e95603fc70f332c87b9f4cebfafaa2d14da5708e183f1089697852}"
export PI_SCRIPTS_ROOT="$PWD/scripts"
export PI_URI="${PI_URI:-https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2025-12-04/2025-12-04-raspios-trixie-arm64-lite.img.xz}"

export XDG_SCRIPTS_ROOT="$XDG_CONFIG_HOME/pi/scripts"
export XDG_SETUP_SCRIPT_PATH="$XDG_CONFIG_HOME/pi/scripts/setup"
export XDG_UPDATE_SCRIPT_PATH="$XDG_CONFIG_HOME/pi/scripts/update"
