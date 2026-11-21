#! /usr/bin/env bash

# Label: Create Configuration
# Description: Create a new XDG configuration using your default editor.
create_configuration() {
  printf "%s\n" "Please select the directory to create you configuration in ('q' to quit):"

  select path in "$XDG_CONFIG_ROOT"/* "$XDG_CONFIG_ROOT"; do
    if [[ -n $path ]]; then
      break
    else
      break
    fi
  done

  if [[ -z "$path" ]]; then
    exit
  fi

  printf "\n"
  read -r -p "Please supply the file name, with relative path (if any), to create ('q' to quit): " name

  if [[ "$name" == "q" ]]; then
    exit
  fi

  path="$path/$name"
  mkdir -p "$(dirname "$path")"

  printf "%s\n" "Editing: $path..."
  "$EDITOR" "$path"
}

# Label: Edit Configuration
# Description: Edits a XDG configuration using your default editor.
edit_configuration() {
  local path=""
  local files=()

  while IFS= read -r file; do
    files+=("$file")
  done < <(find "$XDG_CONFIG_ROOT" -type f -print | sort)

  printf "%s\n" "Please select your desired Pi configuration to edit ('q' to quit):"

  select path in "${files[@]}"; do
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

# Label: List Configurations
# Description: Lists XDG configuration files.
list_configurations() {
  printf "%s\n\n" "You have the following configurations:"

  find "$XDG_CONFIG_ROOT" -type f -print0 | sort -z | while IFS= read -r -d '' file; do
    printf "%s\n" "$file"
  done
}

# Label: Delete Configuration
# Description: Deletes an existing XDG configuration.
delete_configuration() {
  local path=""
  local files=()

  while IFS= read -r file; do
    files+=("$file")
  done < <(find "$XDG_CONFIG_ROOT" -type f -print | sort)

  printf "%s\n\n" "Please select the configuration to delete ('q' to quit):"

  select path in "${files[@]}"; do
    if [[ -n $path ]]; then
      printf "\n"
      rm -i "$path"
      break
    else
      break
    fi
  done

  if [[ -z "$path" ]]; then
    exit
  fi

  if [[ -e "$path" ]]; then
    printf "%s\n" "Skipped: $path."
  else
    printf "%s\n" "Deleted: $path"
  fi
}

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

# Label: Get Basename
# Description: Answers file basename.
# Parameters: $1 (required): The file path.
get_basename() {
  path=${1##*/}
  printf "%s" "${path%.*}"
}

# Label: Uniqueify Files
# Description: Builds list of unique files from two different root directories.
# Parameters: $1 (required): User path, $2 (required): Project path.
uniqueify_files() {
  local -r user_root="$1"
  local -r project_root="$2"
  local -n __files="$3"

  declare -A __seen=()
  __files=()

  for __file in "$user_root"/* "$project_root"/*; do
    [[ -f $__file ]] || continue
    __name=${__file##*/}
    [[ -n ${__seen[$__name]+x} ]] && continue
    __seen[$__name]=1
    __files+=("$__name")
  done
}

# Label: Scripts Path
# Description: Dynamically builds path to scripts.
# Parameters: $1 (required): The relative path.
scripts_path() {
  local relative_path="$1"
  local user_path="$XDG_CONFIG_ROOT/scripts/$relative_path"
  local project_path="$PWD/scripts/$relative_path"

  if [[ -r "$user_path" ]]; then
    printf "%s" "$user_path"
  else
    printf "%s" "$project_path"
  fi
}

# Label: Setup Drive
# Description: Formats and sets up micro SSD for booting a Pi device.
setup_drive() {
  while true; do
    if [[ $# == 0 ]]; then
      printf "\nPlease select your operating system:\n"
      printf "  o: Orange Pi\n"
      printf "  r: Raspberry Pi\n"
      printf "  q: Quit/Exit\n\n"
      read -r -p "Enter selection: " response
      printf "\n"
      process_drive_option "$response"
    else
      process_drive_option "$1"
    fi
    break
  done
}

export -f setup_drive

# Label: Process Drive Option
# Description: Sets up drive based on user selection.
process_drive_option() {
  case $1 in
    'o')
      setup_orange_pi;;
    'r')
      setup_raspberry_pi;;
    'q');;
    *)
      printf "ERROR: Invalid option.\n";;
  esac
}

# Label: Setup Temporary Root
# Description: Cleans and makes temporary root directory.
setup_temp_root() {
  rm -rf "$PI_TEMP_ROOT"
  mkdir "$PI_TEMP_ROOT"
}
