FROM muicoder/alpine:glibc

ENV KUBECTL_VERSION=v1.21.2
ARG url_kubectl=https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl
ARG url_kubeadm=https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubeadm
ENV K3S_VERSION=v1.21.2+k3s2
ARG url_k3s=https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION/k3s
ENV K9S_VERSION=v0.24.14
ARG url_k9s=https://github.com/derailed/k9s/releases/download/$K9S_VERSION/k9s_${K9S_VERSION}_Linux_x86_64.tar.gz
ENV POPEYE_VERSION=v0.9.3
ARG url_popeye=https://github.com/derailed/popeye/releases/download/$POPEYE_VERSION/popeye_Linux_x86_64.tar.gz
ENV KUBECTX_VERSION=v0.9.4
ARG url_kubectx=https://github.com/ahmetb/kubectx/releases/download/$KUBECTX_VERSION/kubectx_${KUBECTX_VERSION}_linux_x86_64.tar.gz
ARG url_kubens=https://github.com/ahmetb/kubectx/releases/download/$KUBECTX_VERSION/kubens_${KUBECTX_VERSION}_linux_x86_64.tar.gz
ENV HELM_VERSION=v3.6.2
ARG url_helm=https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz
ENV KUSTOMIZE_VERSION=v4.2.0
ARG url_kustomize=https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F$KUSTOMIZE_VERSION/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz
ENV JQ_VERSIPN=1.6
ARG url_jq=https://github.com/stedolan/jq/releases/download/jq-$JQ_VERSIPN/jq-linux64
ENV YQ_VERSION=v4.9.8
ARG url_yq=https://github.com/mikefarah/yq/releases/download/$YQ_VERSION/yq_linux_amd64
ENV VELA_VERSION=v1.0.7
ARG url_vela=https://github.com/oam-dev/kubevela/releases/download/$VELA_VERSION/vela-$VELA_VERSION-linux-amd64.tar.gz

RUN set -ex; \
    mkdir /download; \
    cd /download; \
    curl -fsSL https://github.com/stackrox/kube-linter/releases/download/0.2.2/kube-linter-linux.tar.gz | tar -xzvf -; \
    curl -fsSL https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64 -o yq3 && chmod +x yq3; \
    curl -fsSL https://openpolicyagent.org/downloads/latest/opa_linux_amd64 -o opa && chmod +x opa; \
    curl -fsSL https://github.com/open-policy-agent/conftest/releases/download/v0.25.0/conftest_0.25.0_Linux_x86_64.tar.gz | tar -xzvf -; \
    curl -fsSL https://github.com/kubernetes-sigs/kubebuilder/releases/download/v2.3.2/kubebuilder_2.3.2_linux_amd64.tar.gz | tar -xzvf - kubebuilder_2.3.2_linux_amd64/bin/kubebuilder; \
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
