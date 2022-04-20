#!/bin/sh

ROOT_PATH=/custom-tools

helmPlugins() {
  local plugin=$1 plugin_ver=$2
  local plugin_repo existed_ver
  local plugin_fullname
  case $plugin in
  secrets)
    plugin_fullname="helm-$plugin"
    plugin_repo="https://github.com/jkroepke/helm-secrets/releases/download/v$plugin_ver/helm-secrets.tar.gz"
    ;;
  diff)
    plugin_fullname="$plugin"
    plugin_repo="https://github.com/databus23/helm-diff/releases/download/v$plugin_ver/helm-diff-linux-amd64.tgz"
    ;;
  esac
  if echo "$plugin_repo" | grep github >/dev/null; then
    plugin_repo="https://ghproxy.com/$plugin_repo"
  fi
  existed_ver=$(grep version: "$ROOT_PATH/helm-plugins/$plugin_fullname/plugin.yaml" 2>/dev/null | awk '{print $NF}')
  if [ -n "$existed_ver" ]; then
    echo "HELM_PLUGINS::$plugin(existed): ${existed_ver}"
    if ! echo "$existed_ver" | grep "$plugin_ver" >/dev/null 2>&1; then
      rm -rf "$ROOT_PATH/helm-plugins/$plugin_fullname"
      wget -qO- "$plugin_repo" | tar -C "$ROOT_PATH/helm-plugins" -xz
    fi
  else
    echo "Not Found($plugin)"
    mkdir -p "$ROOT_PATH/helm-plugins"
    wget -qO- "$plugin_repo" | tar -C "$ROOT_PATH/helm-plugins" -xz
  fi
  echo "HELM_PLUGINS::$plugin(used): $(grep version: "$ROOT_PATH/helm-plugins/$plugin_fullname/plugin.yaml" 2>/dev/null | awk '{print $NF}')"
  echo
}

get_version() {
  local plugin=$1
  local existed_ver
  case $plugin in
  curl)
    existed_ver=$("$ROOT_PATH/$plugin" --version | grep libcurl | awk '{print $2}')
    ;;
  kubectl)
    existed_ver=$("$ROOT_PATH/$plugin" version --client --short | awk '{print $NF}')
    ;;
  helmfile)
    existed_ver=$("$ROOT_PATH/$plugin" version | awk '{print $NF}')
    ;;
  sops)
    existed_ver=$("$ROOT_PATH/$plugin" help | grep VERSION -A1 | tail -n 1 | awk '{print $NF}')
    ;;
  yq)
    existed_ver=$("$ROOT_PATH/$plugin" --version | awk '{print $NF}')
    ;;
  esac
  echo "$existed_ver"
}

binaryPlugins() {
  local plugin=$1 plugin_ver=$2
  local plugin_repo existed_ver
  case $plugin in
  curl)
    plugin_repo="https://github.com/moparisthebest/static-curl/releases/download/v$plugin_ver/curl-amd64"
    ;;
  kubectl)
    plugin_repo="http://rancher-mirror.cnrancher.com/kubectl/v$plugin_ver/linux-amd64-v$plugin_ver-kubectl"
    ;;
  helmfile)
    plugin_repo="https://github.com/roboll/helmfile/releases/download/v$plugin_ver/helmfile_linux_amd64"
    ;;
  sops)
    plugin_repo="https://github.com/mozilla/sops/releases/download/v$plugin_ver/sops-v$plugin_ver.linux"
    ;;
  yq)
    plugin_repo="https://github.com/mikefarah/yq/releases/download/v$plugin_ver/yq_linux_amd64"
    ;;
  esac
  if echo "$plugin_repo" | grep github >/dev/null; then
    plugin_repo="https://ghproxy.com/$plugin_repo"
  fi
  if command -v "$ROOT_PATH/$plugin" >/dev/null; then
    existed_ver=$(get_version "$plugin")
    echo "$plugin(existed): $existed_ver"
    if ! echo "$existed_ver" | grep "$plugin_ver" >/dev/null 2>&1; then
      rm "$ROOT_PATH/$plugin"
      wget -O "$ROOT_PATH/$plugin" "$plugin_repo"
    fi
  else
    echo "Not Found($plugin)"
    wget -O "$ROOT_PATH/$plugin" "$plugin_repo"
  fi
  chmod a+x "$ROOT_PATH/$plugin"
  existed_ver=$(get_version "$plugin")
  echo "$plugin(used): $existed_ver"
  echo
}

downloadPlugins() {
  for plugin in $BINARY_PLUGINS; do
    binaryPlugins "${plugin%=*}" "${plugin#*=}"
  done
  for plugin in $HELM_PLUGINS; do
    helmPlugins "${plugin%=*}" "${plugin#*=}"
  done
  # for argocd user
  chown 999:999 -R "$ROOT_PATH"
}
downloadPlugins
