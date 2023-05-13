#!/bin/bash

while getopts "u:" opt; do
  case $opt in
  u)
    USERNAME=$OPTARG
    ;;
  *)
    exit 1
    ;;
  esac
done

if [ ! -d "$1" ]; then
  exit 1
fi

# Try to obtain the user name
while true; do
  if test -z $USERNAME; then

    # Get user name from the $USER variable if not root
    if test -n "$USER"; then
      echo -e "Using username $USER for non-root user"
      USERNAME=$USER
      continue
    fi

    # Get the user name from the id executable if it is available and not root
    if command -v id >/dev/null 2>&1; then
      echo -e "Using username $USERNAME for non-root user"
      USERNAME=$(id -u -n)
      continue
    fi

    # If we cannot detect it, just ask
    echo -n "Username for non-root user: "
    read -r USERNAME
    continue
  fi

  # Ensure a user name other than root is chosen
  if [ "$USERNAME" = "root" ]; then
    echo "A user other then root needs to be created"
    USERNAME=""
  else
    break
  fi
done

# Determine the script directory, in which the build.conf file is stored
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do
  SCRIPT_DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
SCRIPT_DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)

# Persist the configuration
echo "USERNAME=$USERNAME" > "$SCRIPT_DIR"/build.conf

# Each image may have additional parameters, let them define it themselves
if test -n "$1"; then
  if [ -f "$1"/configure.sh ]; then
    "$1"/configure.sh
  else
    echo "$(basename $1) contains no configure.sh script"
  fi
fi

# TODO: In the future me might as well get the ports from the image in the registry to support tags, such that this part can end up in the run.sh script
# e.g. skopeo inspect --raw "$image" | jq -r '.manifest.config.ExposedPorts | keys[]
EXPOSE_PORTS=$(awk '/^EXPOSE/ {
  for(i=2; i<=NF; i++) {
    split($i, arr, "/");
    port = arr[1];
    if (!seen[port]) {
      print port;
      seen[port] = 1;
    }
  }
}' "$1/Containerfile")

PORTS_CONF=""
for EXPOSE_PORT  in $EXPOSE_PORTS; do
  echo -n "Protocol on port $EXPOSE_PORT: "
  read -r EXPOSE_PROTOCOL
  PORTS_CONF+="$EXPOSE_PORT=$EXPOSE_PROTOCOL"
done


echo "$PORTS_CONF" > "$1"/ports.conf
