#!/usr/bin/env bash

set -e

if [[ -e /.dockerenv ]]; then
  IN_CLUSTER=true
  AUTH_BEARER="/var/run/secrets/kubernetes.io/serviceaccount/token"
  command -v curl >/dev//null || {
    wget -qO /usr/bin/curl "https://github.com/moparisthebest/static-curl/releases/download/$(wget -qO- "https://api.github.com/repos/moparisthebest/static-curl/releases/latest" | grep .tag_name | awk -F\" '{print $(NF-1)}')/curl-amd64"
    chmod +x /usr/bin/curl
  }
fi

METRICS=${METRICS:-"metrics prometheus"}
RL_KEY=${RL_KEY:-k8s}
SYNC4ARGOPROJ=${SYNC4ARGOPROJ:-argocd.argoproj.io/}

generateServiceMonitor() {
  local name namespace
  local cache_path cache_yaml
  local resourceVersion
  local service_meta service_spec service_port service_port_target service_port_number
  local service_selector metrics_path
  local -A metrics_paths
  for namespace in $(if [[ -n $IN_CLUSTER ]]; then
    curl --silent --insecure --header "Authorization: Bearer $(cat "$AUTH_BEARER")" \
      "https://kubernetes.default/api/v1/namespaces" | jq -r '.items[].metadata.name'
  else
    kubectl get namespaces -o custom-columns=name:.metadata.name --no-headers
  fi); do
    cache_path="/tmp/yaml.cached/$namespace/ServiceMonitor"
    mkdir -p "$cache_path"
    for name in $(if [[ -n $IN_CLUSTER ]]; then
      curl --silent --insecure --header "Authorization: Bearer $(cat "$AUTH_BEARER")" \
        "https://kubernetes.default/api/v1/namespaces/$namespace/services" | jq -r '.items[].metadata.name' | while read -r svc; do
        if curl --silent --insecure --header "Authorization: Bearer $(cat "$AUTH_BEARER")" \
          "https://kubernetes.default/api/v1/namespaces/$namespace/services/$svc" | jq -cr '.metadata' | grep "$SYNC4ARGOPROJ" >/dev/null; then
          echo "$svc"
        fi
      done
    else
      kubectl -n "$namespace" get services -o custom-columns=name:.metadata.name --no-headers |
        while read -r svc; do
          if kubectl get "Service/$svc" -otemplate='{{.metadata}}' -n "$namespace" | grep "$SYNC4ARGOPROJ" >/dev/null; then
            echo "$svc"
          fi
        done
    fi); do
      cache_yaml="$cache_path/$name.yaml"
      service_spec=$(if [[ -n $IN_CLUSTER ]]; then
        curl --silent --insecure --header "Authorization: Bearer $(cat "$AUTH_BEARER")" \
          "https://kubernetes.default/api/v1/namespaces/$namespace/services/$name" | jq -cr '.' >"$namespace.$name.json"
      else
        kubectl -n "$namespace" get service "$name" -o jsonpath="{}" >"$namespace.$name.json"
      fi)
      service_spec=$(jq -cr ".spec" "$namespace.$name.json")
      service_meta=$(jq -cr ".metadata" "$namespace.$name.json")
      if [[ $(jq -r '.clusterIP' <<<"$service_spec") != None ]]; then
        service_selector=$(while read -r label; do echo "      $label: $(echo "$service_meta" | jq -r ".labels.\"$label\"")"; done < <(echo "$service_meta" | jq -cr '.labels|keys[]' 2>/dev/null))
        metrics_paths=()
        while IFS= read -r service_port; do
          service_port_target=$(echo "$service_port" | jq -r .targetPort)
          service_port_number=$(echo "$service_port" | jq -r .port)
          for metrics_path in $METRICS; do
            if wget -T 3 -qO- "$name.$namespace.svc:$service_port_number/$metrics_path" 2>/dev/null | grep -E "^[a-z_]+\{.+=.+\} [0-9.e+-]+" >/dev/null; then
              metrics_paths[$metrics_path.$service_port_number]=$service_port_target
              break
            fi
          done
        done < <(echo "$service_spec" | jq -cr '.ports[]' 2>/dev/null)
        if [[ ${#metrics_paths[@]} -gt 0 ]]; then
          cat <<EOF >>"$cache_yaml"
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: gen-$name
  namespace: $namespace
  annotations:
    generate.file.name: generateServiceMonitor
  labels:
    monitor: generate
spec:
  endpoints:
$(for key in "${!metrics_paths[@]}"; do
            echo "  - path: /${key%.*}"
            echo "    targetPort: ${metrics_paths[$key]}"
            echo "    relabelings:"
            echo "    - action: replace"
            echo "      targetLabel: $RL_KEY"
            echo "      replacement: ${CLUSTER:-kubernetes}"
          done)
  namespaceSelector:
    matchNames:
    - $namespace
  selector:
    matchLabels:
$service_selector
EOF
          if [[ -n $IN_CLUSTER ]]; then
            resourceVersion=$(curl --silent --insecure --header "Authorization: Bearer $(cat "$AUTH_BEARER")" \
              "https://kubernetes.default/apis/monitoring.coreos.com/v1/namespaces/$namespace/servicemonitors/gen-$name" |
              jq -r .metadata.resourceVersion)
            if [[ $resourceVersion == null ]]; then
              curl --silent --insecure --header "Authorization: Bearer $(cat "$AUTH_BEARER")" \
                -XPOST \
                -H "Accept: application/json" \
                -H "Content-Type: application/yaml" \
                --data-binary @"$cache_yaml" \
                "https://kubernetes.default/apis/monitoring.coreos.com/v1/namespaces/$namespace/servicemonitors" | jq -cr .spec
            else
              sed "s/metadata:/metadata:\n  resourceVersion: \"$resourceVersion\"/" <"$cache_yaml" >/tmp/resourceVersion.yaml
              curl --silent --insecure --header "Authorization: Bearer $(cat "$AUTH_BEARER")" \
                -XPUT \
                -H "Accept: application/json" \
                -H "Content-Type: application/yaml" \
                --data-binary @"/tmp/resourceVersion.yaml" \
                "https://kubernetes.default/apis/monitoring.coreos.com/v1/namespaces/$namespace/servicemonitors/gen-$name" | jq -cr .spec
            fi
          else
            if ! kubectl create -f "$cache_yaml" 2>/dev/null; then
              kubectl replace -f "$cache_yaml"
            fi
          fi
        fi
      fi
    done
    # relabeling  RL_KEY=CLUSTER
    if ! kubectl-neat help >/dev/null 2>&1; then
      user_repo=itaysk/kubectl-neat
      version=$(until curl -sL "https://api.github.com/repos/$user_repo/tags" | grep -E '"name": "v[0-9.]+"' | awk -F\" '{print $(NF-1)}' | head -n 1 | cut -dv -f2; do sleep 3; done)
      echo "https://github.com/$user_repo/releases/download/v$version/${user_repo##*/}_linux_amd64.tar.gz"
    else
      for kind in PodMonitor ServiceMonitor; do
        rl_label=$RL_KEY rl_replacement=$CLUSTER yq -e 'with(.items[].spec.*ndpoints[]; .relabelings = [{"action":"replace","targetLabel":strenv(rl_label),"replacement":strenv(rl_replacement)}] )' <(kubectl-neat get -- $kind -n "$namespace") | kubectl replace -f -
      done
    fi
  done
}

generateServiceMonitor
