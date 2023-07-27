#!/bin/bash

HOST_NETWORKING=""

while getopts ":hn:rv:x" opt; do
  case $opt in
  n)
    NAME=$OPTARG
    ;;
  x)
    USE_X11_FORWARDING=1
    ;;
  r)
    REMOVE_AFTER_EXIT=1
    ;;
  v)
    VOLUMES+="-v $OPTARG "
    ;;
  h)
    HOST_NETWORKING+="--net host "
    ;;
  *)
    exit 1
    ;;
  esac
done

shift $((OPTIND - 1))

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
EXPOSE_PORTS=$(awk -F= '{print $1}' "$1"/ports.conf)
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

X11_FORWARDING_ARGS=""
if ! test -z $USE_X11_FORWARDING; then
  if command -v xhost >/dev/null; then
    xhost + local:
  fi

  X11_FORWARDING_ARGS="--env DISPLAY --volume=/tmp/.X11-unix:/tmp/.X11-unix:rw "

  if command -v nvidia-ctk>/dev/null; then
    X11_FORWARDING_ARGS+="--device nvidia.com/gpu=all "
  else
    if [ -d /dev/dri ]; then
      X11_FORWARDING_ARGS+="--device /dev/dri "
    fi
  fi
fi

if test -z $NAME; then
  NAME="$(basename $1)"
fi

if command -v loginctl>/dev/null; then
  PID_1_COMM=""
  if command -v ps >/dev/null; then
    PID_1_COMM=$(ps -p 1 -o comm=)
  elif test -d /proc; then
    PID_1_COMM=$(cat /proc/1/comm)
  else
    echo "could not determine comm of pid 1"
  fi

  if [ ! "$PID_1_COMM" = "systemd" ]; then
    loginctl enable-linger "$(id -u)"
  fi
fi

RUN_ARGS=""
if ! test -z "$2"; then
  RUN_ARGS="$2"
fi

REMOVE_AFTER_EXIT_ARGS=""
if ! test -z $REMOVE_AFTER_EXIT; then
  REMOVE_AFTER_EXIT_ARGS+="--rm "
  if [ -t 1 ]; then
    REMOVE_AFTER_EXIT_ARGS+="--interactive --tty "
  fi

else
  REMOVE_AFTER_EXIT_ARGS+="--detach -it "
fi

IMAGE_NAME=$(basename $1)

set -x

podman run \
  $REMOVE_AFTER_EXIT_ARGS \
  $EXPOSED_PORTS \
  $SHARED_SYS_CERTS_MOUNT \
  --security-opt label=disable \
  --security-opt seccomp=unconfined \
  $VOLUMES \
  --device /dev/fuse:rw \
  $HOST_NETWORKING \
  $X11_FORWARDING_ARGS \
  --name "$NAME" \
  --pids-limit 8096 \
  --hostname "$NAME" \
  "$IMAGE_NAME" $RUN_ARGS
