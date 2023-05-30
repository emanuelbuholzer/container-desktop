#!/bin/bash

SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do
  SCRIPT_DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)
  SOURCE=$(readlink "$SOURCE")
  [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE
done
SCRIPT_DIR=$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)

source "$SCRIPT_DIR"/../build.conf

echo -en "Image to underlay: "
read -rs UNDERLAY_IMAGE
echo

echo -en "Tag of underlay image: "
read -rs UNDERLAY_TAG
echo

cat >"$SCRIPT_DIR"/build.conf <<EOF
IMAGE=$UNDERLAY_IMAGE
TAG=$UNDERLAY_TAG
EOF
