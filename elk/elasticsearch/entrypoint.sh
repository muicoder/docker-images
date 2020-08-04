#!/bin/bash

set -e

if [ "${1#-}" != "$1" ]; then
	set -- gosu elasticsearch tini -- elasticsearch "$@"
fi

if [ "$1" = 'elasticsearch' -a "$(id -u)" = '0' ]; then
	for path in \
		$(dirname $(which elasticsearch))/../data \
		$(dirname $(which elasticsearch))/../logs \
		$(dirname $(which elasticsearch))/../config \
	; do
		mkdir -p "$path"
		chown -R elasticsearch:elasticsearch "$path"
	done
	set -- gosu elasticsearch tini -- "$@"
fi

exec "$@"
