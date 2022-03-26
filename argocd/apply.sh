#!/usr/bin/env bash

set -e

declare -A SOPS_PGP_FP projectMap
SOPS_PGP_FP["name@xxxx.com"]=personal.gpg_public_key

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SCRIPT="$(basename "$0" .sh)"
CLUSTER=${SCRIPT#*-}

CHARTS_DIR="$SCRIPT_DIR/charts"
VALUES_DIR="$SCRIPT_DIR/values"

CLUSTER_DIR="$SCRIPT_DIR/clusters"
GIT_URL="gitlab.xxxx.com:appstore"
GIT_BRANCH="vaas"
TEMP_DIR="/tmp/$(date +%F)/$CLUSTER"

sops_pgp_fp() {
  local sops_pgp_fp=${SOPS_PGP_FP[*]}
  local sops_config="${1:-$SCRIPT_DIR}/.sops.yaml"
  mkdir -p "$(dirname "$sops_config")"
  cat <<EOF >"$sops_config"
  creation_rules:
  - path_regex: values.*/.*crypted.*.yaml
    encrypted_regex: .*KEY.*|.*SECRET.*|.*pass.*|.*PASS.*|.*URI.*|.*tls.*|.*dockerconfig.*|regex
    pgp: >-
      ${sops_pgp_fp// /,}
EOF
}

gen_topology() {
  local topology=$1
  local default_topology="$VALUES_DIR/topology.sh"
  if [[ "${projectMap[$CLUSTER]}" == "all" ]]; then
    cp -a "$default_topology" "$topology"
  else
    head -n "$(grep -n '^"$' "$default_topology" | awk -F: '{print $1}')" "$default_topology" >"$topology"
    for proj in ${projectMap[$CLUSTER]}; do
      grep "projectMap\[\"$proj\"\]" "$default_topology" >>"$topology" || true
    done
  fi
}

sops_pgp_fp
while IFS= read -r kind; do
  while IFS= read -r unencrypted; do
    yq e -i -P '.instances|sort_by(.name)|sort_keys(..)|{"instances":.}' "$unencrypted"
  done < <(find "$VALUES_DIR/$kind" -type f) | sort
done < <(
  while IFS= read -r path; do
    echo "${path##*/}"
  done < <(find "$VALUES_DIR" -type d -name '[A-Z]*') | sort
)
case $CLUSTER in
dev-test)
  SOPS_PGP_FP["$cluster"]=dev-test.gpg_public_key
  ;;
prod)
  SOPS_PGP_FP["$cluster"]=prod.gpg_public_key
  ;;
*)
  echo -e "invalid cluster: $CLUSTER"
  exit
  ;;
esac
sops_pgp_fp "$CLUSTER_DIR/$CLUSTER"

cd "$CLUSTER_DIR/$CLUSTER" && {
  mkdir -p "values"
  gen_topology "values/topology.sh"
  while IFS= read -r encrypted; do
    current="values${encrypted##*values}"
    [[ -s "$current" ]] || cp -a "$encrypted" "$current"
  done < <(find "$VALUES_DIR" -type f -name "[A-Z]*.encrypted*.y?ml")
  while IFS= read -r encrypted; do
    if sops -d "$encrypted" >/dev/null; then
      sops updatekeys --yes "$encrypted"
    else
      yq e -i -P '.instances|sort_by(.name)|sort_keys(..)|{"instances":.}' "$encrypted"
      sops -e -i "$encrypted" || yq e "$encrypted"
    fi
  done < <(find "values" -type f -name "[A-Z]*.encrypted*.y?ml")
  $(which rm) -rf "$TEMP_DIR"
  git clone --branch=${GIT_BRANCH:-master} "git@$GIT_URL/$CLUSTER/config.git" "$TEMP_DIR"
  if [[ -n $1 ]]; then
    cd "$TEMP_DIR"
    git reset --hard "$1"
    cd -
  fi
  cp -a "$CHARTS_DIR" "$VALUES_DIR" "$SCRIPT_DIR/vaas" "$SCRIPT_DIR/README.md" "$TEMP_DIR"
  cp -a "$PWD/" "$TEMP_DIR"
}

cd "$TEMP_DIR" && {
  git checkout "$(date +%G-%V)" || git checkout -b "$(date +%G-%V)"
  git add --all .
  if [[ -n $1 ]]; then
    git commit --all --message "initial vaas for ConfigMap/Secret/Middleware"
    git push -f origin "$(date +%G-%V)"
    git checkout "${GIT_BRANCH:-master}" || git checkout -b "${GIT_BRANCH:-master}"
    git merge "$(date +%G-%V)"
    git push -f origin "${GIT_BRANCH:-master}"
  else
    git commit --all --message "$(date +%F_%T%z)"
    git push -o merge_request.create -o merge_request.target=${GIT_BRANCH:-master} origin "$(date +%G-%V):$(date +%G-%V)"
  fi
}
