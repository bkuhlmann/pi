#! /usr/bin/env bash

# Label: Edit Configuration
# Description: Edits a XDG configuration using your default editor.
edit_configuration() {
  local path=""

  printf "%s\n" "Please select your desired Pi configuration to edit (use 'q' to quit):"

  select path in $XDG_CONFIG_HOME/pi/**/*; do
    if [[ -n $path ]]; then
      printf "%s\n" "Editing: $path..."
      "$EDITOR" "$path"
      break
    else
      break
    fi
  done
}

export -f edit_configuration

# Label: Eject
# Description: Ejects (unmounts) micro SSD card.
eject_card() {
  diskutil eject "bootfs"
}
export -f eject_card

# Label: Open Configuration
# Description: Opens entire XDG configuration in default editor.
open_configuration() {
  local root="$XDG_CONFIG_HOME/pi"

  printf "%s\n" "Opening: $root..."
  "$EDITOR" "$root"
}

export -f open_configuration

# Label: Setup Card
# Description: Formats and sets up micro SSD card for booting a Raspberry Pi device.
setup_card() {
  local disk_number=""
  local host_path=""
  local network_path=""
  local docker_script_path="$PWD/scripts/docker"
  local projects_script_path="$PWD/scripts/projects"
  local setup_script_path="$PWD/scripts/setup"
  local update_script_path="$PWD/scripts/update"

  read -r -p "Have you inserted your micro SSD card for formatting (y/n)? " disk_ready

  if [[ "$disk_ready" != "y" ]]; then
    printf "%s\n" "ERROR: Raspberry Pi card formatting aborted."
    exit 1
  fi

  printf "\n%s\n\n" "Please select your host configuration:"

  select host_path in $XDG_CONFIG_HOME/pi/hosts/*; do
    if [[ -n $host_path ]]; then
      break
    else
      printf "%s\n" "ERROR: Invalid selection."
      exit 1
    fi
  done

  printf "\n%s\n\n" "Please select your network configuration:"

  select network_path in $XDG_CONFIG_HOME/pi/networks/*; do
    if [[ -n $network_path ]]; then
      break
    else
      printf "%s\n" "ERROR: Invalid selection."
      exit 1
    fi
  done

  if [[ -x "$XDG_PROJECTS_SCRIPT_PATH" ]]; then
    projects_script_path="$XDG_PROJECTS_SCRIPT_PATH"
  fi

  if [[ -x "$XDG_DOCKER_SCRIPT_PATH" ]]; then
    docker_script_path="$XDG_DOCKER_SCRIPT_PATH"
  fi


  if [[ -x "$XDG_SETUP_SCRIPT_PATH" ]]; then
    setup_script_path="$XDG_SETUP_SCRIPT_PATH"
  fi


  if [[ -x "$XDG_UPDATE_SCRIPT_PATH" ]]; then
    update_script_path="$XDG_UPDATE_SCRIPT_PATH"
  fi

  printf "\n%s\n" "Using host configuration: $host_path."
  printf "%s\n" "Using network configuration: $network_path."
  printf "%s\n" "Using projects script: $projects_script_path."
  printf "%s\n" "Using Docker script: $docker_script_path."
  printf "%s\n" "Using setup script: $setup_script_path."
  printf "%s\n" "Using update script: $update_script_path."

  printf "\n%s\n\n" "The following external disks are detected for your micro SSD:"
  diskutil list external

  while ! [[ "$disk_number" =~ ^[0-9]+$ ]]; do
    read -r -p "Please enter your disk number (i.e. 1, 2, 3) for /dev/disk to format " disk_number
  done

  if [[ -z "$disk_number" ]]; then
    printf "%s\n" "ERROR: Invalid disk number."
    exit 1
  fi

  "$OS_CLI" --cli \
            --disable-eject \
            --cloudinit-networkconfig "$network_path" \
            --cloudinit-userdata "$host_path" \
            --sha256 "$OS_INTEGRITY" \
            "$OS_URI" "/dev/disk$disk_number"

  cp "$projects_script_path" "/Volumes/bootfs/projects"
  cp "$docker_script_path" "/Volumes/bootfs/docker"
  cp "$setup_script_path" "/Volumes/bootfs/setup"
  cp "$update_script_path" "/Volumes/bootfs/update"

  printf "%s\n" "Raspberry Pi SSD card is ready!"
  printf "%s\n" "Please eject card before using."
}
export -f setup_card
