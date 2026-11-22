#! /usr/bin/env bash

# Defines shared functionality for all installers.

export INSTALL_ROOT="$HOME/apps"

# Label: Setup
# Description: Provisions the application directory for install. Idempotent.
setup() {
  mkdir -p "$INSTALL_ROOT"
}
