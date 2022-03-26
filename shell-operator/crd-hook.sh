#!/usr/bin/env bash

hook::config() {
  cat <<EOF
configVersion: v1
kubernetes:
- apiVersion: sre.io/v1
  kind: Application
  executeHookOnEvent:
  - Added
  - Modified
  - Deleted
EOF
}

hook::trigger() {
  local type watchEvent hook_version
  local kind name namespace
  local name_image name_command name_port replicas
  local cache_path cache_yaml
  type=$(jq -r '.[0].type' "${BINDING_CONTEXT_PATH}")
  watchEvent=$(jq -r '.[0].watchEvent' "${BINDING_CONTEXT_PATH}")
  if [[ -x /shell-operator ]]; then
    hook_version=$(/shell-operator version | awk '{print $NF}')
  else
    hook_version="https://github.com/flant/shell-operator"
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

    mkdir -p "$cache_path"
    cache_yaml="$cache_path/$name.yaml"

    name_image=$(jq -r '.[0].object.spec.image' "${BINDING_CONTEXT_PATH}")
    name_command=$(jq -r '.[0].object.spec.command' "${BINDING_CONTEXT_PATH}")
    if [[ $name_command == null ]]; then
      name_command='[ "tail", "-f", "/etc/hosts" ]'
    fi
    name_port=$(jq -r '.[0].object.spec.port' "${BINDING_CONTEXT_PATH}")
    replicas=$(jq -r '.[0].object.spec.replicas' "${BINDING_CONTEXT_PATH}")
    if [[ $replicas == null ]]; then
      replicas=1
    fi
    cat <<EOF >"$cache_yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $name
  namespace: $namespace
  labels:
    app.kubernetes.io/name: $name
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: $name
  template:
    metadata:
      labels:
        app.kubernetes.io/name: $name
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - podAffinityTerm:
                labelSelector:
                  matchLabels:
                    app.kubernetes.io/name: $name
                topologyKey: kubernetes.io/hostname
              weight: 100
      containers:
        - name: $name
          image: $name_image
          command: $(echo $name_command)
EOF
    if [[ $name_port != null ]]; then
      cat <<EOF >>"$cache_yaml"
          ports:
            - containerPort: $name_port
EOF
    fi
    cat <<EOF >>"$cache_yaml"
  replicas: $replicas
  minReadySeconds: 5
  revisionHistoryLimit: 3
  progressDeadlineSeconds: 10
EOF
    case $watchEvent in
    Added)
      kubectl create -f "$cache_yaml"
      ;;
    Modified)
      kubectl apply -f "$cache_yaml"
      ;;
    Deleted)
      kubectl delete -f "$cache_yaml"
      ;;
    esac
    echo "$(date +%F_%T): $kind $name was $watchEvent" | tee >>"$cache_path/$name.log"
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
