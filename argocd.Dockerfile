ARG CACHE_VERSION=canary
ARG CACHE_IMAGE=ghcr.io/helmfile/helmfile
FROM $CACHE_IMAGE:$CACHE_VERSION AS cache
WORKDIR /usr/local/bin
COPY ajam cmp ./
RUN wget -qO- https://github.com/itaysk/kubectl-neat/releases/download/v2.0.4/kubectl-neat_linux_$([ $(arch) = x86_64 ] && echo amd64 || echo arm64).tar.gz | tar -xz kubectl-neat
RUN wget -qOargocd-vault-plugin https://github.com/argoproj-labs/argocd-vault-plugin/releases/download/v1.18.1/argocd-vault-plugin_1.18.1_linux_$([ $(arch) = x86_64 ] && echo amd64 || echo arm64)
RUN apk --no-cache add binutils file && chmod a+x * && strip helmfile && rm age age-keygen && ls -lt
FROM alpine:latest
WORKDIR /plugins
COPY --from=cache --chown=999:0 /usr/local/bin .
RUN ./ajam age:rage age-keygen:rage-keygen btm:bottom btop curl diffoci dnslookup etcd etcdctl etcdutl gitui jq mc ncdu nerdctl netstat procs systemctl-tui ttyd wget yq && \
    ./ajam kmon mqttui pping tspin:tailspin tcpdump trip xplr iostat mpstat
