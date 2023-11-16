FROM muicoder/k9s:latest AS gotty
WORKDIR /gotty
ARG TARGETPLATFORM
RUN tar -xzf /k9s.tgz && wget -SOkubectl https://dl.k8s.io/release/v1.29.15/bin/$TARGETPLATFORM/kubectl
FROM kubeoperator/webkubectl:latest
COPY --chown=65534:65534 --chmod=0755 --from=gotty /gotty /usr/bin/
