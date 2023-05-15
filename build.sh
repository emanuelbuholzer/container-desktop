#!/bin/bash

if [ ! -d "$1" ]; then
  echo "first argument is not a directory"
  exit 1
fi

# Determine the script directory, in which the build.sh.conf file is stored
SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do
  SCRIPT_DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
SCRIPT_DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)

# If there are some shared system certificates, we might as well mount them
SHARED_SYS_CERTS_MOUNT=""
SHARED_SYS_CERTS="/etc/pki/ca-trust/source/anchors"
if [ -d "$SHARED_SYS_CERTS" ]; then
  SHARED_SYS_CERTS_MOUNT="--volume /etc/pki/ca-trust/source/anchors:/etc/pki/ca-trust/source/anchors:ro"
fi


PODMAN_VERSION=$(podman version -f '{{.Version}}')
PODMAN_MAJOR_VERSION="${PODMAN_VERSION%%.*}"
PODMAN_MINOR_VERSION="${PODMAN_VERSION#*.}"
PODMAN_MINOR_VERSION="${PODMAN_MINOR_VERSION%%.*}"

IMAGE_BUILD_CONF=""
if [ -f "$1"/build.conf ]; then
  if ((PODMAN_MAJOR_VERSION >= 4 && PODMAN_MINOR_VERSION >= 5)); then
    IMAGE_BUILD_CONF="--build-arg-file "$SCRIPT_DIR"/build.conf --build-arg-file $1/build.conf"
  else
    IMAGE_BUILD_CONF=$(awk -F= '{printf "--build-arg %s=%s ", $1, $2}' $1/build.conf "$SCRIPT_DIR"/build.conf)
  fi
fi

echo $IMAGE_BUILD_CONF

# Mangle together the final build.sh command, yes, with word splitting x)
podman build \
  $IMAGE_BUILD_CONF \
  $SHARED_SYS_CERTS_MOUNT \
  --tag "$(basename "$1")" \
  "$1"
