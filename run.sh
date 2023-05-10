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

if [ ! -d "$1" ]; then
  echo "first argument is not a directory"
  exit 1
fi

SHARED_SYS_CERTS_MOUNT=""
SHARED_SYS_CERTS="/etc/pki/ca-trust/source/anchors"
if [ -d "$SHARED_SYS_CERTS" ]; then
  SHARED_SYS_CERTS_MOUNT="--volume /etc/pki/ca-trust/source/anchors:/etc/pki/ca-trust/source/anchors:ro"
fi

EXPOSED_PORTS=""
EXPOSE_PORTS=$(cat "$1"/ports.conf)
for EXPOSE_PORT in $EXPOSE_PORTS; do
  EXPOSED_PORT=$EXPOSE_PORT
  while true; do
    if command -v ss >/dev/null; then
      if ! ss -tulpn | grep "$EXPOSED_PORT" >/dev/null 2>&1; then
        break
      fi
    elif command -v lsof >/dev/null; then
      if ! lsof -i -P -n | grep "$EXPOSED_PORT" >/dev/null 2>&1; then
        break
      fi
    fi
    ((EXPOSED_PORT++))
  done
  EXPOSED_PORTS+="--publish $EXPOSED_PORT:$EXPOSE_PORT "
  echo "Publishing $EXPOSE_PORT under $EXPOSED_PORT"
done


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
  PID_1_COMM=""
  if command -v ps >/dev/null; then
    PID_1_COMM=$(ps -p 1 -o comm=)
  elif test -d /proc; then
    PID_1_COMM=$(cat /proc/1/comm)
  else
    echo "could not determine comm of pid 1"
  fi

  if ! "$PID_1_COMM" = "systemd"; then
    loginctl enable-linger "$(id -u)"
  fi
fi

podman run \
  --detach \
  $EXPOSED_PORTS \
  $SHARED_SYS_CERTS_MOUNT \
  --security-opt label=disable \
  --security-opt seccomp=unconfined \
  --privileged \
  --device /dev/fuse:rw \
  --name "$NAME" \
  "$1"
