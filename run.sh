#!/bin/bash

while getopts "n:" opt; do
  case $opt in
  n)
    NAME=$OPTARG
    ;;
  *)
    exit 1
    ;;
  esac
done

SHARED_SYS_CERTS_MOUNT=""
SHARED_SYS_CERTS="/etc/pki/ca-trust/source/anchors"
if [ -d "$SHARED_SYS_CERTS" ]; then
  SHARED_SYS_CERTS_MOUNT="--volume /etc/pki/ca-trust/source/anchors:/etc/pki/ca-trust/source/anchors:ro"
fi

RFB_PORT=5900
while true; do
  if command -v ss; then
    if ! ss -tulpn | grep $RFB_PORT >/dev/null 2>&1; then
      break
    fi
  elif command -v lsof; then
    if ! lsof -i -P -n | grep $RFB_PORT >/dev/null 2>&1; then
      break
    fi
  fi
  ((RFB_PORT++))
done
echo "Using rfb port $RFB_PORT"

# Try to obtain the name
while true; do
  if test -z $NAME; then
    echo -n "Container name: "
    read -r NAME
  else
    break
  fi
done

if command -v loginctl; then
  loginctl enable-linger "$(id -u)"
fi

podman run \
  --detach \
  --publish $RFB_PORT:5901 \
  $SHARED_SYS_CERTS_MOUNT \
  --security-opt label=disable \
  --security-opt seccomp=unconfined \
  --privileged \
  --device /dev/fuse:rw \
  --name "$NAME" \
  "$1"
