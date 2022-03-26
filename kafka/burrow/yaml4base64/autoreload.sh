#!/usr/bin/env sh

burrow_addr=${1:-127.0.0.1:8000}

until [ "$(curl -s "$burrow_addr/burrow/admin/ready")" = READY ]; do sleep 5; done

while true; do
  sleep 5m
  for obj in $(curl -s "$burrow_addr/metrics" | grep ^burrow | grep _status | grep -v '} 1$' | sed -E 's~^.+cluster="([^".]+)".+consumer_group="([^".]+)".+(\d)~cluster=\1,consumer_group=\2,\3~g' | sort | uniq); do
    curl -X DELETE "$burrow_addr/v3/kafka/$(echo "$obj" | awk -F, '{print $1}')/consumer/$(echo "$obj" | awk -F, '{print $2}')" && echo
  done
done
