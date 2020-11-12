FROM muicoder/alpine:k8s AS k8s
WORKDIR /rc
RUN find /usr/local/bin -type f -perm /+x -exec mv {} . \;; \
    mv helm helm_v3; \
    ls -l
FROM rancher/rancher:v2.4.16 AS rc
WORKDIR /rc
RUN find /usr/bin -type f -perm /+x -size +5M -exec mv {} . \;; \
    mv /usr/bin/*.sh .; \
    mv /usr/bin/tini .; \ 
    ls -l
COPY --from=k8s /rc /rc
FROM ubuntu:bionic
ARG VERSION=v2.4.16
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y git curl ca-certificates unzip xz-utils && \
    useradd rancher && \
    mkdir -p /var/lib/rancher/etcd /var/lib/cattle /opt/jail /opt/drivers/management-state/bin && \
    chown -R rancher /var/lib/rancher /var/lib/cattle /usr/local/bin && \
    mkdir /root/.kube && \
    ln -s /etc/rancher/k3s/k3s.yaml /root/.kube/k3s.yaml  && \
    ln -s /etc/rancher/k3s/k3s.yaml /root/.kube/config && \
    ln -s /usr/bin/rancher /usr/bin/reset-password && \
    ln -s /usr/bin/rancher /usr/bin/ensure-default-admin && \
    ln -sf /bin/bash /bin/sh
WORKDIR /var/lib/rancher

ARG ARCH=amd64
ARG IMAGE_REPO=muicoder
ARG SYSTEM_CHART_DEFAULT_BRANCH=release-v2.4
ARG DASHBOARD_BRANCH=release-2.4
# kontainer-driver-metadata branch to be set for specific branch, logic at rancher/rancher/pkg/settings/setting.go
ARG RANCHER_METADATA_BRANCH=release-v2.4

ENV CATTLE_SYSTEM_CHART_DEFAULT_BRANCH=$SYSTEM_CHART_DEFAULT_BRANCH \
    CATTLE_HELM_VERSION=v2.16.8-rancher1 \
    CATTLE_K3S_VERSION=v1.17.17+k3s1 \
    CATTLE_MACHINE_VERSION=v0.15.0-rancher46 \
    CATTLE_ETCD_VERSION=v3.4.3 \
    CATTLE_CHANNELSERVER_VERSION=v0.3.0 \
    LOGLEVEL_VERSION=v0.1.3 \
    TINI_VERSION=v0.18.0 \
    TELEMETRY_VERSION=v0.5.14 \
    KUBECTL_VERSION=v1.21.3 \
    DOCKER_MACHINE_LINODE_VERSION=v0.1.8 \
    LINODE_UI_DRIVER_VERSION=v0.3.0 \
    RANCHER_METADATA_BRANCH=${RANCHER_METADATA_BRANCH} \
    CATTLE_DASHBOARD_INDEX=https://releases.rancher.com/dashboard/${DASHBOARD_BRANCH}/index.html \
    HELM_VERSION=v3.6.2 \
    KUSTOMIZE_VERSION=v4.2.0

RUN mkdir -p /var/lib/rancher-data/local-catalogs/system-library && \
    mkdir -p /var/lib/rancher-data/local-catalogs/library && \
    mkdir -p /var/lib/rancher-data/local-catalogs/helm3-library && \
    git clone -b $CATTLE_SYSTEM_CHART_DEFAULT_BRANCH --single-branch https://github.com/rancher/system-charts /var/lib/rancher-data/local-catalogs/system-library && \
    git clone -b master --single-branch https://github.com/rancher/charts /var/lib/rancher-data/local-catalogs/library && \
    git clone -b master --single-branch https://github.com/rancher/helm3-charts /var/lib/rancher-data/local-catalogs/helm3-library

COPY --from=rc /rc /usr/bin
COPY --from=rc /opt/drivers/management-state/bin /opt/drivers/management-state/bin

ENV TINI_URL_amd64=https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini \
    TINI_URL_arm64=https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-arm64 \
    TINI_URL=TINI_URL_${ARCH} \
    HELM_URL_V2_amd64=https://github.com/rancher/helm/releases/download/${CATTLE_HELM_VERSION}/rancher-helm \
    HELM_URL_V2_arm64=https://github.com/rancher/helm/releases/download/${CATTLE_HELM_VERSION}/rancher-helm-arm64 \
    HELM_URL_V2=HELM_URL_V2_${ARCH} \
    HELM_URL_V3=https://get.helm.sh/helm-${HELM_VERSION}-linux-${ARCH}.tar.gz \
    TILLER_URL_amd64=https://github.com/rancher/helm/releases/download/${CATTLE_HELM_VERSION}/rancher-tiller \
    TILLER_URL_arm64=https://github.com/rancher/helm/releases/download/${CATTLE_HELM_VERSION}/rancher-tiller-arm64 \
    TILLER_URL=TILLER_URL_${ARCH} \
    K3S_URL_amd64=https://github.com/rancher/k3s/releases/download/${CATTLE_K3S_VERSION}/k3s \
    K3S_URL_arm64=https://github.com/rancher/k3s/releases/download/${CATTLE_K3S_VERSION}/k3s-arm64 \
    K3S_URL=K3S_URL_${ARCH} \
    CHANNELSERVER_URL_amd64=https://github.com/rancher/channelserver/releases/download/${CATTLE_CHANNELSERVER_VERSION}/channelserver-amd64 \
    CHANNELSERVER_URL_arm64=https://github.com/rancher/channelserver/releases/download/${CATTLE_CHANNELSERVER_VERSION}/channelserver-arm64 \
    CHANNELSERVER_URL=CHANNELSERVER_URL_${ARCH} \
    ETCD_URL_amd64=https://github.com/etcd-io/etcd/releases/download/${CATTLE_ETCD_VERSION}/etcd-${CATTLE_ETCD_VERSION}-linux-amd64.tar.gz \
    ETCD_URL_arm64=https://github.com/etcd-io/etcd/releases/download/${CATTLE_ETCD_VERSION}/etcd-${CATTLE_ETCD_VERSION}-linux-arm64.tar.gz \
    ETCD_URL=ETCD_URL_${ARCH} \
    KUSTOMIZE_URL_amd64=https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz \
    KUSTOMIZE_URL_arm64=https://github.com/brendarearden/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_arm64.tar.gz \
    KUSTOMIZE_URL=KUSTOMIZE_URL_${ARCH}

ENV CATTLE_UI_PATH=/usr/share/rancher/ui \
    CATTLE_UI_VERSION=2.4.48 \
    CATTLE_CLI_VERSION=v2.4.11 \
    CATTLE_API_UI_VERSION=1.1.9

RUN mkdir -p /var/log/auditlog && \
    ln -s /usr/bin/rancher-helm /usr/bin/helm && \
    ln -s /usr/bin/rancher-tiller /usr/bin/tiller && \
    mkdir -p /var/lib/rancher-data/driver-metadata

ENV AUDIT_LOG_PATH=/var/log/auditlog/rancher-api-audit.log \
    AUDIT_LOG_MAXAGE=10 \
    AUDIT_LOG_MAXBACKUP=10 \
    AUDIT_LOG_MAXSIZE=100 \
    AUDIT_LEVEL=0

COPY --from=rc /usr/share/rancher/ui $CATTLE_UI_PATH

ENV CATTLE_CLI_URL_DARWIN=https://releases.rancher.com/cli2/${CATTLE_CLI_VERSION}/rancher-darwin-amd64-${CATTLE_CLI_VERSION}.tar.gz \
    CATTLE_CLI_URL_LINUX=https://releases.rancher.com/cli2/${CATTLE_CLI_VERSION}/rancher-linux-amd64-${CATTLE_CLI_VERSION}.tar.gz \
    CATTLE_CLI_URL_WINDOWS=https://releases.rancher.com/cli2/${CATTLE_CLI_VERSION}/rancher-windows-386-${CATTLE_CLI_VERSION}.zip

COPY --from=rc /var/lib/rancher-data/driver-metadata /var/lib/rancher-data/driver-metadata

ENV CATTLE_AGENT_IMAGE=${IMAGE_REPO}/rancher-agent:${VERSION} \
    CATTLE_SERVER_IMAGE=${IMAGE_REPO}/rancher \
    CATTLE_SERVER_VERSION=${VERSION} \
    ETCD_UNSUPPORTED_ARCH=${ARCH} \
    ETCDCTL_API=3 \
    SSL_CERT_DIR=/etc/rancher/ssl

ENTRYPOINT ["entrypoint.sh"]
