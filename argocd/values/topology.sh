#!/usr/bin/env bash

set -e

declare -A projectMap
projectMap["all"]="
docker-registry
tls
compress
http2https
"
projectMap["sre"]="common"
