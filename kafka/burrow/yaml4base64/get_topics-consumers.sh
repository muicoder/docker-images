#!/usr/bin/env sh

burrow_addr=${1:-127.0.0.1:8000}
if curl -sL "$burrow_addr/v3/admin/loglevel" | jq -r .level 2>/dev/null; then
  burrow_kafka="$burrow_addr/v3/kafka"
  for cluster in $(curl -sL "$burrow_kafka" | jq -r .clusters[]); do
    echo
    echo "TopicList::$cluster"
    curl -sL "$burrow_kafka/$cluster/topic" | jq -r .topics[] | sort
    echo
    echo "ConsumerList::$cluster"
    curl -sL "$burrow_kafka/$cluster/consumer" | jq -r .consumers[] | sort
  done
else
  echo "Please enter a valid burrow httpserver"
fi

echo
curl -s "$burrow_addr/metrics" | grep ^burrow | grep _status | grep -v '} 1$'
