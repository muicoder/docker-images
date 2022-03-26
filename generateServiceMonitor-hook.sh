#!/usr/bin/env bash

set -e

METRICS=${METRICS:-"metrics prometheus"}
RL_KEY=${RL_KEY:-k8s}
SYNC4ARGOPROJ=${SYNC4ARGOPROJ:-argocd.argoproj.io/}

hook::config() {
  cat <<EOF
configVersion: v1
kubernetes:
- apiVersion: v1
  kind: Service
  executeHookOnEvent:
  - Added
  - Deleted
EOF
}

hook::trigger() {
  local type watchEvent hook_version
  local kind name namespace
  local cache_path cache_yaml
  type=$(jq -r '.[0].type' "${BINDING_CONTEXT_PATH}")
  watchEvent=$(jq -r '.[0].watchEvent' "${BINDING_CONTEXT_PATH}")
  if [[ -x /shell-operator ]]; then
    hook_version=$(/shell-operator version | awk '{print $NF}')
  else
    hook_version="shell-operator"
  fi
  case $type in
  Synchronization)
    : handle existing objects
    : jq '.[0].objects | ... '
    ;;
  Event)
    kind=$(jq -r '.[0].object.kind' "${BINDING_CONTEXT_PATH}")
    name=$(jq -r '.[0].object.metadata.name' "${BINDING_CONTEXT_PATH}")
    namespace=$(jq -r '.[0].object.metadata.namespace' "${BINDING_CONTEXT_PATH}")
    cache_path="/tmp/yaml.cached/$namespace/$kind"
    if ! jq -cr '.[0].object.metadata' "${BINDING_CONTEXT_PATH}" | grep "$SYNC4ARGOPROJ" >/dev/null; then
      echo "NotFound $SYNC4ARGOPROJ for $kind/$name($namespace)"
      return
    fi
    mkdir -p "$cache_path"
    cache_yaml="$cache_path/$name.yaml"

    ### get_resource
    local service_meta service_spec service_port service_port_target service_port_number
    local service_selector metrics_path
    local -A metrics_paths
    service_spec=$(jq -cr '.[0].object.spec' "${BINDING_CONTEXT_PATH}")
    service_meta=$(jq -cr '.[0].object.metadata' "${BINDING_CONTEXT_PATH}")
    if [[ $(jq -r '.clusterIP' <<<"$service_spec") != None ]]; then
      service_selector=$(while read -r label; do echo "      $label: $(echo "$service_meta" | jq -r ".labels.\"$label\"")"; done < <(echo "$service_meta" | jq -cr '.labels|keys[]' 2>/dev/null))
      metrics_paths=()
      while IFS= read -r service_port; do
        service_port_target=$(echo "$service_port" | jq -r .targetPort)
        service_port_number=$(echo "$service_port" | jq -r .port)
        for metrics_path in $METRICS; do
          for i in $(seq 3); do
            sleep "$i"s
            if wget -T "$i" -qO- "$name.$namespace.svc:$service_port_number/$metrics_path" 2>/dev/null | grep -E "^[a-z_]+\{.+=.+\} [0-9.e+-]+" >/dev/null; then
              metrics_paths[$metrics_path.$service_port_number]=$service_port_target
              break
            fi
          done
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
      fi
    fi
    ### get_resource

    case $watchEvent in
    Added)
      if [[ -s "$cache_yaml" ]]; then
        if ! kubectl create -f "$cache_yaml" 2>/dev/null; then
          kubectl replace -f "$cache_yaml"
        fi
      fi
      ;;
    Deleted)
      kubectl -n "$namespace" label ServiceMonitor "gen-$name" monitor- || true
      ;;
    esac
    ;;
  esac
}

common::run_hook() {
  if [[ $1 == "--config" ]]; then
    hook::config
  else
    hook::trigger
  fi
}
common::run_hook "$@"
