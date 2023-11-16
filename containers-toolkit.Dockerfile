FROM nvcr.io/nvidia/k8s/cuda-sample:devicequery-cuda11.7.1-ubuntu20.04 AS devicequery
FROM nvcr.io/nvidia/k8s/cuda-sample:vectoradd-cuda11.7.1-ubuntu20.04 AS vectoradd
FROM alpine:latest AS cache
ARG TARGETOS
ARG TARGETARCH
ARG VERSION=1.18.2
WORKDIR /tmp/artifacts
RUN if [ $TARGETARCH = amd64 ]; then ALIASARCH=x86_64; else ALIASARCH=aarch64; fi && \
      wget -qO- https://github.com/NVIDIA/nvidia-container-toolkit/releases/download/v$VERSION/nvidia-container-toolkit_${VERSION}_deb_$TARGETARCH.tar.gz | tar --strip-components=4 -xzv && \
      wget -qO- https://github.com/NVIDIA/nvidia-container-toolkit/releases/download/v$VERSION/nvidia-container-toolkit_${VERSION}_rpm_$ALIASARCH.tar.gz | tar --strip-components=4 -xzv && \
      chown 0:0 *$VERSION-*
COPY --from=devicequery /cuda-samples/deviceQuery /tmp/usr/local/bin/
COPY --from=vectoradd /cuda-samples/vectorAdd /tmp/usr/local/bin/
FROM alpine:latest
RUN apk add --no-cache gcompat libstdc++
WORKDIR /artifacts
COPY --from=cache /tmp /
