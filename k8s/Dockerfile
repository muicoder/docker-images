FROM muicoder/alpine:glibc

ENV KUBECTL_VERSION=1.20.15
ARG url_kubectl=https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl
ARG url_kubeadm=https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VERSION/bin/linux/amd64/kubeadm
ENV K3S_VERSION=1.20.15+k3s2
ARG url_k3s=https://github.com/k3s-io/k3s/releases/download/v$K3S_VERSION/k3s
ENV K9S_VERSION=0.25.18
ARG url_k9s=https://github.com/derailed/k9s/releases/download/v$K9S_VERSION/k9s_$v{K9S_VERSION}_Linux_x86_64.tar.gz
ENV POPEYE_VERSION=0.9.8
ARG url_popeye=https://github.com/derailed/popeye/releases/download/v$POPEYE_VERSION/popeye_Linux_x86_64.tar.gz
ENV KUBECTX_VERSION=0.9.4
ARG url_kubectx=https://github.com/ahmetb/kubectx/releases/download/v$KUBECTX_VERSION/kubectx_v${KUBECTX_VERSION}_linux_x86_64.tar.gz
ARG url_kubens=https://github.com/ahmetb/kubectx/releases/download/v$KUBECTX_VERSION/kubens_v${KUBECTX_VERSION}_linux_x86_64.tar.gz
ENV HELM_VERSION=3.7.2
ARG url_helm=https://get.helm.sh/helm-v$HELM_VERSION-linux-amd64.tar.gz
ENV KUSTOMIZE_VERSION=4.5.3
ARG url_kustomize=https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv$KUSTOMIZE_VERSION/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz
ENV JQ_VERSIPN=1.6
ARG url_jq=https://github.com/stedolan/jq/releases/download/jq-$JQ_VERSIPN/jq-linux64
ENV YQ_VERSION=4.24.2
ARG url_yq=https://github.com/mikefarah/yq/releases/download/v$YQ_VERSION/yq_linux_amd64
ENV VELA_VERSION=1.2.5
ARG url_vela=https://github.com/oam-dev/kubevela/releases/download/v$VELA_VERSION/vela-v$VELA_VERSION-linux-amd64.tar.gz
ENV OPA_CONFTEST_VERSION=0.30.0 \
    KUBEBUILDER_VERSION=3.3.0

RUN set -ex; \
    mkdir /download; \
    cd /download; \
    curl -fsSL https://github.com/stackrox/kube-linter/releases/download/0.2.6/kube-linter-linux.tar.gz | tar -xzvf -; \
    curl -fsSL https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 -o yq3 && chmod +x yq3; \
    curl -fsSL https://github.com/mikefarah/yq/releases/download/v4.16.2/yq_linux_amd64  -o yq4 && chmod +x yq4; \
    curl -fsSL https://openpolicyagent.org/downloads/latest/opa_linux_amd64 -o opa && chmod +x opa; \
    curl -fsSL https://github.com/open-policy-agent/conftest/releases/download/v$OPA_CONFTEST_VERSION/conftest_${OPA_CONFTEST_VERSION}_Linux_x86_64.tar.gz | tar -xzvf -; \
    curl -fsSL https://github.com/kubernetes-sigs/kubebuilder/releases/download/v$KUBEBUILDER_VERSION/kubebuilder_${KUBEBUILDER_VERSION}_linux_amd64.tar.gz | tar -xzvf - kubebuilder_${KUBEBUILDER_VERSION}_linux_amd64/bin/kubebuilder; \
    for url in $(env | grep url); \
    do \
        URL=$(echo $url | cut -d= -f2); \
        echo $URL; \
        if [[ ${URL##*.} = gz ]]; then \
            curl -fsSL $URL | tar -xzvf -; \
        elif [[ ${URL##*.} = zip ]]; then \
            curl -fsSL $URL -o tmp.zip; \
            unzip -q tmp.zip; \
        else \
            FILE=$(echo ${URL##*/} | cut -d_ -f1 | cut -d- -f1); \
            curl -fsSL $URL -o $FILE; \
            chmod +x $FILE; \
        fi; \
    done && find . -type f -perm /+x -exec mv -v {} /usr/local/bin \;; \
    rm -rf /download
