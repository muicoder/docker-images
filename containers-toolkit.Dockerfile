FROM alpine:3.16 AS cache
ARG TARGETOS
ARG TARGETARCH
ARG VERSION=1.18.1
WORKDIR /artifacts
RUN if [ $TARGETARCH = amd64 ]; then ALIASARCH=x86_64; else ALIASARCH=aarch64; fi && \
      wget -qO- https://github.com/NVIDIA/nvidia-container-toolkit/releases/download/v$VERSION/nvidia-container-toolkit_${VERSION}_deb_$TARGETARCH.tar.gz | tar --strip-components=4 -xzv && \
      wget -qO- https://github.com/NVIDIA/nvidia-container-toolkit/releases/download/v$VERSION/nvidia-container-toolkit_${VERSION}_rpm_$ALIASARCH.tar.gz | tar --strip-components=4 -xzv
FROM alpine:3.16
WORKDIR /artifacts
COPY --from=cache --chown=999:0 /artifacts .
