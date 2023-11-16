ARG CACHE_VERSION=canary
ARG CACHE_IMAGE=ghcr.io/helmfile/helmfile
FROM $CACHE_IMAGE:$CACHE_VERSION AS cache
WORKDIR /usr/local/bin
COPY ajam cmp ./
RUN apk --no-cache add binutils file && strip helmfile && rm age age-keygen && ls -lt
FROM alpine:3.16
WORKDIR /plugins
COPY --from=cache --chown=999:0 /usr/local/bin .
RUN ./ajam age:rage age-keygen:rage-keygen btm:bottom btop curl diffoci dnslookup etcd etcdctl etcdutl gitui gpg-tui jq mc ncdu nerdctl netstat nfs-cat nfs-cp nfs-ls nfs-stat pkgtop procs systemctl-tui ttyd websocat wget yq && \
    ./ajam simplehttpserver:go-simplehttpserver kmon mqttui pping rustcan systeroid tspin:tailspin tcpdump trip xplr cifsiostat iostat mpstat pidstat tapestat