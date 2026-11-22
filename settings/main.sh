#! /usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'

export PI_TEMPLATES_ROOT="$PWD/lib/templates"
export PI_TEMP_ROOT="$PWD/tmp"

export XDG_CONFIG_ROOT="$XDG_CONFIG_HOME/pi"
