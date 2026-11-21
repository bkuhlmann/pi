#! /usr/bin/env bash

# Label: Setup Raspberry Pi
# Description: Formats and sets up micro SSD for booting a Raspberry Pi device.
setup_raspberry_pi() {
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

  printf "\n%s\n\n" "Found the following external disks:"
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
