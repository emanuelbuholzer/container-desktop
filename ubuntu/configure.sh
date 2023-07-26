#!/bin/bash

# Determine the script directory, in which the parent build.conf file is stored
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do
  SCRIPT_DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
SCRIPT_DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)

# Source the parent build configuration
source "$SCRIPT_DIR"/../build.conf

# Determine the passwords
echo -en "Password for $USERNAME: "
read -rs PASSWORD_USERNAME
echo

echo -en "Password for root: "
read -rs PASSWORD_ROOT
echo

# Yes, there should be another solutions for secrets x)
cat >"$SCRIPT_DIR"/build.conf <<EOF
PASSWORD_USERNAME=$PASSWORD_USERNAME
PASSWORD_ROOT=$PASSWORD_ROOT
EOF


