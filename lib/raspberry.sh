#! /usr/bin/env bash

# Label: Crate Raspberry Profile
# Description: Create new XDG profile configuration.
create_raspberry_profile() {
  local name="r-five"
  local time_zone="America/Denver"
  local user_name="pi"
  local user_password=""
  local user_key=""
  local template_path="$PI_TEMPLATES_ROOT/raspberry/profile.yml"

  printf "%s\n\n" "Let's create your profile!"
  read -r -p "Enter your profile/host name (i.e. $name): " name
  read -r -p "Enter your time zone (i.e. $time_zone): " time_zone
  read -r -p "Enter your user name (i.e. $user_name): " user_name

  printf "%s\n" "Enter your user password"
  user_password="$(openssl passwd -6)"

  printf "%s\n" "Select your user public SSH key"

  select profile_public_path in "$HOME"/.ssh/*.pub; do
    if [[ -n $profile_public_path ]]; then
      user_key="$(cat "$profile_public_path")"
      break
    else
      printf "%s\n" "SSH configuration skipped."
      break
    fi
  done

  xdg_path="$XDG_CONFIG_ROOT/profiles/$name.yml"

  mkdir -p "$XDG_CONFIG_ROOT/profiles"

  NAME="$name" \
  TIME_ZONE="$time_zone" \
  USER_NAME="$user_name" \
  USER_PASSWORD="$user_password" \
  USER_KEY="$user_key" \
  envsubst '$NAME $TIME_ZONE $USER_NAME $USER_PASSWORD $USER_KEY' < "$template_path" > "$xdg_path"

  printf "\n%s\n" "Created: $xdg_path"
  printf "%s\n" "Feel free to edit the above to personalize further."
}

# Label: Crate Raspberry Network
# Description: Create new XDG network configuration.
create_raspberry_network() {
  local name="r-pi"
  local country="US"
  local ssid="Pi"
  local password="secret"
  local template_path="$PI_TEMPLATES_ROOT/raspberry/network.yml"

  printf "%s\n\n" "Let's fill in your network information!"
  read -r -p "Enter your network name (i.e. $name): " name
  read -r -p "Enter your country (i.e. $country): " country
  read -r -s -p "Enter your network SSID: " ssid
  printf "\n"
  read -r -s -p "Enter your network password: " password
  printf "\n"

  xdg_path="$XDG_CONFIG_ROOT/networks/$name.yml"

  mkdir -p "$XDG_CONFIG_ROOT/networks"

  COUNTRY="$country" \
  NETWORK_SSID="$ssid" \
  NETWORK_PASSWORD="$password" \
  envsubst '$COUNTRY $NETWORK_SSID $NETWORK_PASSWORD' < "$template_path" > "$xdg_path"

  printf "\n%s\n" "Created: $xdg_path"
  printf "%s\n" "Feel free to edit the above to personalize further."
}

# Label: Setup Raspberry Pi
# Description: Formats and sets up micro SSD for booting a Raspberry Pi device.
setup_raspberry_pi() {
  local disk_number=""
  local volume_path="/Volumes/bootfs"

  setup_temp_root

  printf "%s\n" "Downloading and decompressing image..."

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
         https://downloads.raspberrypi.com/raspios_lite_arm64_latest
  )

  curl --location \
       --retry 3 \
       --retry-all-errors \
       --retry-max-time 10 \
       --fail \
       --remove-on-error \
       --remote-name \
       --remote-header-name \
       --output-dir "$PI_TEMP_ROOT" \
       https://downloads.raspberrypi.com/raspios_lite_arm64_latest.sha256

  (
    cd "$PI_TEMP_ROOT"
    printf "\n%s\n" "Checking operating system integrity..."
    sha256sum --strict --check "$download.sha256"
    xz --decompress --keep "$download"
  )

  printf "\n%s\n\n" "Found the following external disks:"
  diskutil list external

  while ! [[ "$disk_number" =~ ^[0-9]+$ ]]; do
    read -r -p "Enter your disk number (i.e. 1, 2, 3) for /dev/disk to format: " disk_number
  done

  if [[ -z "$disk_number" ]]; then
    printf "%s\n" "ERROR: Invalid disk number."
    exit 1
  fi

  disk="/dev/disk${disk_number}"

  printf "\n%s\n" "Formatting Disk ${disk_number}..."
  diskutil unmountDisk "$disk"
  sudo dd if="${download%.*}" of="$disk" bs=4m status=progress

  printf "%s\n\n" "Select your profile to add to the image:"

  select profile_path in "$XDG_CONFIG_ROOT"/profiles/*; do
    if [[ -n $profile_path ]]; then
      printf "\n"
      break
    else
      printf "%s\n" "ERROR: Invalid selection."
      exit 1
    fi
  done

  printf "%s\n\n" "Select your network to add to the image:"

  select network_path in $XDG_CONFIG_HOME/pi/networks/*; do
    if [[ -n $network_path ]]; then
      break
    else
      printf "%s\n" "ERROR: Invalid selection."
      exit 1
    fi
  done

  printf "\n%s\n" "Applying configuration..."
  cp -v "$profile_path" "$volume_path/user-data"
  cp -v "$network_path" "$volume_path/network-config"

  installers=()
  uniqueify_files "$XDG_CONFIG_ROOT/scripts/installers" "$PWD/scripts/installers" installers

  mkdir -p "$volume_path/installers"

  for installer in "${installers[@]}"; do
    path="$(scripts_path "installers/$installer")"
    cp -v "${path}" "$volume_path/installers/$installer"
  done

  diskutil eject "$disk"

  printf "\n%s\n" "Setup Complete! You can remove your SSD drive."
}
