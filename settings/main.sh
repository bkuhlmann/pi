#! /usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

export OS_CLI="${OS_CLI:-/Applications/Raspberry Pi Imager.app/Contents/MacOS/rpi-imager}"
export OS_URI="${OS_URI:-https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2025-12-04/2025-12-04-raspios-trixie-arm64-lite.img.xz}"
export OS_INTEGRITY="${OS_INTEGRITY:-d2a54d6a13e95603fc70f332c87b9f4cebfafaa2d14da5708e183f1089697852}"

export XDG_DOCKER_SCRIPT_PATH="$XDG_CONFIG_HOME/pi/scripts/docker"
export XDG_PROJECTS_SCRIPT_PATH="$XDG_CONFIG_HOME/pi/scripts/projects"
export XDG_SETUP_SCRIPT_PATH="$XDG_CONFIG_HOME/pi/scripts/setup"
export XDG_UPDATE_SCRIPT_PATH="$XDG_CONFIG_HOME/pi/scripts/update"
