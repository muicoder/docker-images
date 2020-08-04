#!/bin/bash

set -e

if [ "$ELASTICSEARCH_URL" ]; then
	sed -ri "s!^(\#\s*)?(elasticsearch\.url:).*!\2 '$ELASTICSEARCH_URL'!" $(dirname $(which kibana))/../config/kibana.yml
fi

if [ "${1#-}" != "$1" ]; then
	set -- gosu kibana tini -- kibana "$@"
fi

if [ "$1" = 'kibana' -a "$(id -u)" = '0' ]; then
	for path in \
		$(dirname $(which kibana))/../data \
		$(dirname $(which kibana))/../logs \
		$(dirname $(which kibana))/../config \
	; do
		mkdir -p "$path"
		chown -R kibana:kibana "$path"
	done
	set -- gosu kibana tini -- "$@"
fi

exec "$@"
