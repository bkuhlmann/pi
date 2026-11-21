#! /usr/bin/env bash

# Label: Setup Orange Pi
# Description: Formats and sets up micro SSD for booting a Orange Pi device.
setup_orange_pi() {
  local disk_number=""

  setup_temp_root

  printf "%s\n" "Downloading and decompressing operating system image..."

  download=$(
    curl --location \
         --progress-bar \
         --retry 3 \
         --retry-all-errors \
         --retry-max-time 10 \
         --fail \
         --remove-on-error \
         --remote-name \
         --remote-header-name \
         --output-dir "$PI_TEMP_ROOT" \
         --write-out '%{filename_effective}' \
         https://dl.armbian.com/orangepizero3w/Trixie_vendor_minimal
  )

  curl --location \
       --silent \
       --retry 3 \
       --retry-all-errors \
       --retry-max-time 10 \
       --fail \
       --remove-on-error \
       --remote-name \
       --remote-header-name \
       --output-dir "$PI_TEMP_ROOT" \
       https://dl.armbian.com/orangepizero3w/Trixie_vendor_minimal.sha

  (
    cd "$PI_TEMP_ROOT"
    printf "\n%s\n" "Checking operating system integrity..."
    sha256sum --check "$download.sha"
    xz --decompress --keep "$download"
  )

  printf "\n%s\n\n" "Found the following external disks:"
  diskutil list external

  while ! [[ "$disk_number" =~ ^[0-9]+$ ]]; do
    read -r -p "Please enter your disk number (i.e. 1, 2, 3) for /dev/disk to format: " disk_number
  done

  if [[ -z "$disk_number" ]]; then
    printf "%s\n" "ERROR: Invalid disk number."
    exit 1
  fi

  disk="/dev/disk${disk_number}"
  partition="${disk}s1"

  diskutil unmountDisk "$disk"
  printf "\n%s\n" "Formatting Disk ${disk_number}..."
  sudo dd if="${download%.*}" of="$disk" bs=4m status=progress

  printf "\n%s\n\n" "Please select a profile to add to your image:"

  select profile_path in "$XDG_CONFIG_ROOT"/profiles/*; do
    if [[ -n $profile_path ]]; then
      printf "\n"
      break
    else
      printf "%s\n" "ERROR: Invalid selection."
      exit 1
    fi
  done

  sudo e2cp -O 0 -G 0 -P 600 -v "$profile_path" "$partition:/root/.not_logged_in_yet"
  sudo e2cp -O 0 -G 0 -P 600 -v "$(scripts_path booters/orange.sh)" \
                                "$partition:/root/provisioning.sh"

  installers=()
  uniqueify_files "$XDG_CONFIG_ROOT/scripts/installers" "$PWD/scripts/installers" installers

  sudo e2mkdir -O 0 -G 0 -P 0755 -v "$partition:/etc/skel/installers"

  for installer in "${installers[@]}"; do
    path="$(scripts_path "installers/$installer")"
    sudo e2cp -O 0 -G 0 -P 0755 -v "${path}" "$partition:/etc/skel/installers/$installer"
  done

  profile_name=$(get_basename "$profile_path")
  hostname_path="${PI_TEMP_ROOT}/hostname.txt"

  printf "%s\n" "$profile_name" > "${hostname_path}"
  sudo e2cp -O 0 -G 0 -P 644 -v "${hostname_path}" "$partition:/etc/hostname"

  printf "\n%s\n" "Please select your public key ('q' to quit):"

  select ssh_path in "$HOME"/.ssh/*.pub; do
    if [[ -n $ssh_path ]]; then
      sudo e2mkdir -O 0 -G 0 -P 700 -v "$partition:/etc/skel/.ssh"
      sudo e2cp -O 0 -G 0 -P 600 -v "$ssh_path" "$partition:/etc/skel/.ssh/authorized_keys"
      break
    else
      printf "%s\n" "SSH configuration skipped."
      break
    fi
  done

  printf "\n%s\n" "Profile installed: $profile_name"
  diskutil eject "/dev/disk${disk_number}"
  printf "\n%s\n" "Setup Complete! Please remove your SSD drive."
}
