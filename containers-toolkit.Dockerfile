FROM alpine:latest AS cache
ARG TARGETOS
ARG TARGETARCH
ARG VERSION=1.18.2
WORKDIR /artifacts
RUN if [ $TARGETARCH = amd64 ]; then ALIASARCH=x86_64; else ALIASARCH=aarch64; fi && \
      wget -O- https://github.com/NVIDIA/nvidia-container-toolkit/releases/download/v$VERSION/nvidia-container-toolkit_${VERSION}_deb_$TARGETARCH.tar.gz | tar --strip-components=4 -xzv && \
      wget -O- https://github.com/NVIDIA/nvidia-container-toolkit/releases/download/v$VERSION/nvidia-container-toolkit_${VERSION}_rpm_$ALIASARCH.tar.gz | tar --strip-components=4 -xzv
FROM busybox:stable-glibc
WORKDIR /artifacts
COPY --from=cache --chown=999:0 /artifacts .
