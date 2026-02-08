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

# Label: Copy Script
# Description: Copies an executable script. Skips if otherwise.
# Parameters: $1 (required): The input path, $2 (required): The output root.
copy_script() {
  local input_path="$1"
  local output_root="$2"

  if [[ -x "$input_path" ]]; then
    name="$(basename "$input_path")"
    output_path="$output_root/$name"

    cp "$input_path" "$output_path"
    printf "%s\n" "Copied: $input_path to $output_path."
  else
    printf "%s\n" "Skipped copy because script isn't executable: $input_path."
  fi
}
export -f copy_script

# Label: Copy Services
# Description: Copy service scripts to boot disk.
copy_services() {
  local output_root="$PI_BOOT_ROOT/services"

  mkdir -p "$output_root"

  for path in "$PI_SCRIPTS_ROOT"/services/*; do
    copy_script "$path" "$output_root"
  done

  for path in "$XDG_SCRIPTS_ROOT"/services/*; do
    copy_script "$path" "$output_root"
  done
}

export -f copy_services

# Label: Setup Card
# Description: Formats and sets up micro SSD card for booting a Raspberry Pi device.
setup_card() {
  local disk_number=""
  local host_path=""
  local network_path=""
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

  printf "\n%s\n" "Using host configuration: $host_path."
  printf "%s\n" "Using network configuration: $network_path."
  printf "%s\n" "Using setup script: $setup_script_path."
  printf "%s\n" "Using update script: $update_script_path."

  printf "\n%s\n\n" "The following external disks are detected for your micro SSD:"
  diskutil list external

  while ! [[ "$disk_number" =~ ^[0-9]+$ ]]; do
    read -r -p "Please enter your disk number (i.e. 1, 2, 3) for /dev/disk to format: " disk_number
  done

  if [[ -z "$disk_number" ]]; then
    printf "%s\n" "ERROR: Invalid disk number."
    exit 1
  fi

  "$PI_CLI" --cli \
            --disable-eject \
            --cloudinit-networkconfig "$network_path" \
            --cloudinit-userdata "$host_path" \
            --sha256 "$PI_INTEGRITY" \
            "$PI_URI" "/dev/disk$disk_number"

  printf "\n"
  copy_script "$setup_script_path" "$PI_BOOT_ROOT"
  copy_script "$update_script_path" "$PI_BOOT_ROOT"
  copy_services

  printf "\n%s\n" "Raspberry Pi SSD card is ready!"
  printf "%s\n" "Please eject card before using."
}
export -f setup_card
