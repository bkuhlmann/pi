#! /usr/bin/env bash

# Defines command line prompt options.

# Label: Process Options
# Description: Executes selected option.
# Parameters: $1 (required): The option number.
process_option() {
  case $1 in
    's')
      setup_drive;;
    'op')
      create_orange_profile;;
    'rp')
      create_raspberry_profile;;
    'rn')
      create_raspberry_network;;
    'c')
      create_configuration;;
    'e')
      edit_configuration;;
    'l')
      list_configurations;;
    'o')
      open_configuration;;
    'd')
      delete_configuration;;
    'E')
      eject_card;;
    'q');;
    *)
      printf "ERROR: Invalid option.\n";;
  esac
}
