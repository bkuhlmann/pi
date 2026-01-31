#! /usr/bin/env bash

# Defines command line prompt options.

# Label: Process Options
# Description: Executes selected option.
# Parameters: $1 (required): The option number.
process_option() {
  case $1 in
    's')
      setup_card;;
    'e')
      edit_configuration;;
    'o')
      open_configuration;;
    'E')
      eject_card;;
    'q');;
    *)
      printf "ERROR: Invalid option.\n";;
  esac
}
export -f process_option
