#!/bin/sh

if ! [ -d "$1" ]; then
  echo "Please input: registryDir"
  exit
fi

DATAregistry="${1:-registry}"
NEWregistry="${2:-docker.io}"
OLDregistry="localhost:${3:-5000}"

sealos registry serve filesystem "$DATAregistry" -p "${OLDregistry#*:}" &
PID=$!
until curl -sSL "$OLDregistry/v2/" 2>/dev/null; do sleep 1; done
curl -sSL "$OLDregistry/v2/_catalog" | awk -F[ '{print $NF}' | awk -F] '{print $1}' | sed 's~"~~g;s~,~\n~g' |
  while read image; do
    curl -sSL "$OLDregistry//v2/$image/tags/list" | awk -F[ '{print $NF}' | awk -F] '{print $1}' | sed 's~"~~g;s~,~\n~g' |
      while read tag; do echo "$image:$tag"; done
  done |
  while read it; do
    sealos pull --policy=always "$OLDregistry/$it" >/dev/null &&
      sealos tag "$OLDregistry/$it" "$NEWregistry/$it" &&
      sealos rmi --force "$OLDregistry/$it" >/dev/null
  done
kill -9 $PID
