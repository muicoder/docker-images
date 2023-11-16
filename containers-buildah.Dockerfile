FROM ubuntu:20.04 AS build
# https://github.com/nicholasdille/buildah-static/blob/main/Dockerfile
ARG VERSION=main
WORKDIR /tmp/buildah
RUN apt-get update && apt-get -y install --no-install-recommends git ca-certificates wget && \
    git clone --config advice.detachedHead=false --depth 1 --branch "${VERSION}" https://github.com/containers/buildah .
RUN apt-get -y install --no-install-recommends make gcc bats btrfs-progs \
    libapparmor-dev libdevmapper-dev libglib2.0-dev libgpgme11-dev libseccomp-dev libselinux1-dev \
    go-md2man && rm /usr/local/sbin/unminimize
ENV CFLAGS='-static -pthread' \
    LDFLAGS='-s -w -static-libgcc -static' \
    EXTRA_LDFLAGS='-s -w -linkmode external -extldflags "-static -lm"' \
    BUILDTAGS='static netgo osusergo exclude_graphdriver_btrfs exclude_graphdriver_devicemapper seccomp apparmor selinux' \
    CGO_ENABLED=1
RUN echo IyEvYmluL3NoCgpBUkNIPSQoY2FzZSAkKHVuYW1lIC1tKSBpbgphbWQ2NCB8IHg4Nl82NCkKICBlY2hvIGFtZDY0CiAgOzsKYXJtNjQgfCBhYXJjaDY0KQogIGVjaG8gYXJtNjQKICA7Owplc2FjKQoKd2dldCAtcU9nby50Z3ogImh0dHBzOi8vZ28uZGV2L2RsL2dvJHsxOi0xLjIxLjl9LmxpbnV4LSRBUkNILnRhci5neiIK | base64 -d | sh -s -- 1.25.6 && \
    rm -rf /tmp/go && tar -xzf go.tgz -C /tmp && export PATH="/tmp/go/bin:$PATH" && go version && \
    make bin/buildah && bin/buildah version

FROM alpine:latest
COPY --from=build /tmp/buildah/bin /usr/local/sbin
