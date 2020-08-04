#!/bin/bash

set -e

if [ "${1#-}" != "$1" ]; then
	set -- gosu logstash tini -- logstash "$@"
fi

if [ "$1" = 'logstash' -a "$(id -u)" = '0' ]; then
	for path in \
		$(dirname $(which logstash))/../data \
		$(dirname $(which logstash))/../logs \
		$(dirname $(which logstash))/../config \
	; do
		mkdir -p "$path"
		chown -R logstash:logstash "$path"
	done
	set -- gosu logstash tini -- "$@"
fi

exec "$@"
