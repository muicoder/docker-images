#!/usr/bin/env sh

DINGTALK_API=${DINGTALK_API:-"https://oapi.dingtalk.com/robot/send?access_token="}
DINGTALK_TMPL="config/default-dingtalk-post.tmpl"
WECOM_API=${WECOM_API:-"https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key="}
WECOM_TMPL="config/default-wecom-post.tmpl"

command -v kcat && {
  for kv in $CLUSTERS; do
    cluster=${kv%=*}
    servers=${kv#*=}
    kcat -b "$servers" -L >"$(date +%F).metadata.kafka_$cluster.txt"
  done
}

echo IyEvdXNyL2Jpbi9lbnYgc2gKCmJ1cnJvd19hZGRyPSR7MTotMTI3LjAuMC4xOjgwMDB9CmlmIGN1cmwgLXNMICIkYnVycm93X2FkZHIvdjMvYWRtaW4vbG9nbGV2ZWwiIHwganEgLXIgLmxldmVsIDI+L2Rldi9udWxsOyB0aGVuCiAgYnVycm93X2thZmthPSIkYnVycm93X2FkZHIvdjMva2Fma2EiCiAgZm9yIGNsdXN0ZXIgaW4gJChjdXJsIC1zTCAiJGJ1cnJvd19rYWZrYSIgfCBqcSAtciAuY2x1c3RlcnNbXSk7IGRvCiAgICBlY2hvCiAgICBlY2hvICJUb3BpY0xpc3Q6OiRjbHVzdGVyIgogICAgY3VybCAtc0wgIiRidXJyb3dfa2Fma2EvJGNsdXN0ZXIvdG9waWMiIHwganEgLXIgLnRvcGljc1tdIHwgc29ydAogICAgZWNobwogICAgZWNobyAiQ29uc3VtZXJMaXN0OjokY2x1c3RlciIKICAgIGN1cmwgLXNMICIkYnVycm93X2thZmthLyRjbHVzdGVyL2NvbnN1bWVyIiB8IGpxIC1yIC5jb25zdW1lcnNbXSB8IHNvcnQKICBkb25lCmVsc2UKICBlY2hvICJQbGVhc2UgZW50ZXIgYSB2YWxpZCBidXJyb3cgaHR0cHNlcnZlciIKZmkKCmVjaG8KY3VybCAtcyAiJGJ1cnJvd19hZGRyL21ldHJpY3MiIHwgZ3JlcCBeYnVycm93IHwgZ3JlcCBfc3RhdHVzIHwgZ3JlcCAtdiAnfSAxJCcK | base64 -d >get_topics-consumers.sh

webhook_tmpl() {
  mkdir -p "$(dirname "$DINGTALK_TMPL")"
  [ -s "$DINGTALK_TMPL" ] || cat <<EOF >"$DINGTALK_TMPL"
$(echo eyJtc2d0eXBlIjogIm1hcmtkb3duIiwibWFya2Rvd24iOiB7InRpdGxlIjoiS2Fma2EgTGFnQ2hlY2tlciIsICJ0ZXh0IjogIgp7ey0gJFN0YXR1c1VSTCA6PSAiaHR0cHM6Ly9wa2cuZ28uZGV2L2dpdGh1Yi5jb20vbGlua2VkaW4vQnVycm93L2NvcmUvcHJvdG9jb2wjU3RhdHVzQ29uc3RhbnQifX0Ke3stICRGb3JtYXRTdHJpbmcgOj0gIjIwMDYtMDEtMDIgMTU6MDQ6MDUifX0KIyBLYWZrYToge3suQ2x1c3Rlcn19Cua2iOi0uee7hPCfkYl7ey5Hcm91cH19e3stIHdpdGggLlJlc3VsdC5TdGF0dXN9fQp7ey0gaWYgZXEgLiAwfX1Ob3RGb3VuZHt7ZW5kfX0Ke3stIGlmIGVxIC4gMX195q2j5bi4e3tlbmR9fQp7ey0gaWYgZXEgLiAyfX3mu57lkI57e2VuZH19Cnt7LSBpZiBlcSAuIDN9feW8guW4uHt7ZW5kfX0Ke3stIGVuZH19CioqU3RhdHVzOioqIFRvdGFsKFBhcnRpdGlvbnM9e3suUmVzdWx0LlRvdGFsUGFydGl0aW9uc319LExhZz17ey5SZXN1bHQuVG90YWxMYWd9fSlbe3stIHdpdGggLlJlc3VsdC5TdGF0dXN9fQp7ey0gaWYgZXEgLiAwfX1Ob3RGb3VuZHt7ZW5kfX0Ke3stIGlmIGVxIC4gMX19e3sufX17e2VuZH19Cnt7LSBpZiBlcSAuIDJ9fXt7Ln19e3tlbmR9fQp7ey0gaWYgZXEgLiAzfX17ey59fXt7ZW5kfX0Ke3stIGVuZH19XSh7eyRTdGF0dXNVUkx9fSnwn5GIe3twcmludGYgIiUuMmYiIC5SZXN1bHQuQ29tcGxldGV9fQp7ey0gaWYgZXEgLlJlc3VsdC5TdGF0dXMgMSB9fQoqKk1heExhZ0RldGFpbHM6KioKe3stIHdpdGggLlJlc3VsdC5NYXhsYWd9fQp7ey5Ub3BpY319W3t7LlN0YXR1cy5TdHJpbmd9fV0oKXt7cHJpbnRmICIlLjJmIiAuQ29tcGxldGV9fQpcdFBhcnRpdGlvbj17ey5QYXJ0aXRpb259ffCfk4hMYWc9e3suQ3VycmVudExhZ319e3tpZiAuT3duZXJ9feKEue+4j3t7Lk93bmVyfX0ve3tlbmR9fXt7aWYgLkNsaWVudElEfX17ey5DbGllbnRJRH19e3tlbmR9fQp7ey0gZW5kfX0Ke3stIGVuZH19Cnt7LSAkVG90YWxFcnJvcnMgOj0gbGVuIC5SZXN1bHQuUGFydGl0aW9uc319Cnt7LSBpZiAkVG90YWxFcnJvcnN9fQojIyMge3skVG90YWxFcnJvcnN9fSBwYXJ0aXRpb25zIGhhdmUgcHJvYmxlbXMoTWF4TGFnPXt7LlJlc3VsdC5NYXhsYWd8bWF4bGFnfX0pCj4qKkNvdW50UGFydGl0aW9uczoqKgp7ey0gcmFuZ2UgJGssJHYgOj0gLlJlc3VsdC5QYXJ0aXRpb25zfHBhcnRpdGlvbmNvdW50c319Cnt7LSBpZiBuZSAkdiAwfX1cblx0e3ska319PXt7JHZ9fXt7ZW5kfX0Ke3stIGVuZH19CioqVG9waWNzQnlTdGF0dXM6KioKe3stIHJhbmdlICRrLCR2IDo9IC5SZXN1bHQuUGFydGl0aW9uc3x0b3BpY3NieXN0YXR1c319Clx0e3ska319PXt7JHZ9fQp7ey0gZW5kfX0KKipQYXJ0aXRpb25EZXRhaWxzOioqCnt7LSByYW5nZSAuUmVzdWx0LlBhcnRpdGlvbnN9fQp7ey5Ub3BpY319W3t7LlN0YXR1cy5TdHJpbmd9fV0oKXt7cHJpbnRmICIlLjJmIiAuQ29tcGxldGV9fQpcdFBhcnRpdGlvbj17ey5QYXJ0aXRpb259ffCfk4hMYWc9e3suQ3VycmVudExhZ319e3tpZiAuT3duZXJ9feKEue+4j3t7Lk93bmVyfX0ve3tlbmR9fXt7aWYgLkNsaWVudElEfX17ey5DbGllbnRJRH19e3tlbmR9fQp7ey0gZW5kfX0Ke3stIGVuZH19CiIKfX0K | base64 -d)
EOF
  mkdir -p "$(dirname "$WECOM_TMPL")"
  [ -s "$WECOM_TMPL" ] || cat <<EOF >"$WECOM_TMPL"
$(echo eyJtc2d0eXBlIjogIm1hcmtkb3duIiwibWFya2Rvd24iOiB7ImNvbnRlbnQiOiAiCnt7LSAkU3RhdHVzVVJMIDo9ICJodHRwczovL3BrZy5nby5kZXYvZ2l0aHViLmNvbS9saW5rZWRpbi9CdXJyb3cvY29yZS9wcm90b2NvbCNTdGF0dXNDb25zdGFudCJ9fQp7ey0gJEZvcm1hdFN0cmluZyA6PSAiMjAwNi0wMS0wMiAxNTowNDowNSJ9fQojIEthZmthOiB7ey5DbHVzdGVyfX0K5raI6LS557uE8J+RiXt7Lkdyb3VwfX17ey0gd2l0aCAuUmVzdWx0LlN0YXR1c319Cnt7LSBpZiBlcSAuIDB9fU5vdEZvdW5ke3tlbmR9fQp7ey0gaWYgZXEgLiAxfX08Zm9udCBjb2xvcj1cImluZm9cIj7mraPluLg8L2ZvbnQ+e3tlbmR9fQp7ey0gaWYgZXEgLiAyfX08Zm9udCBjb2xvcj1cIndhcm5pbmdcIj7mu57lkI48L2ZvbnQ+e3tlbmR9fQp7ey0gaWYgZXEgLiAzfX08Zm9udCBjb2xvcj1cImNvbW1lbnRcIj7lvILluLg8L2ZvbnQ+e3tlbmR9fQp7ey0gZW5kfX0KKipTdGF0dXM6KiogVG90YWwoUGFydGl0aW9ucz17ey5SZXN1bHQuVG90YWxQYXJ0aXRpb25zfX0sTGFnPXt7LlJlc3VsdC5Ub3RhbExhZ319KVt7ey0gd2l0aCAuUmVzdWx0LlN0YXR1c319Cnt7LSBpZiBlcSAuIDB9fU5vdEZvdW5ke3tlbmR9fQp7ey0gaWYgZXEgLiAxfX08Zm9udCBjb2xvcj1cImluZm9cIj57ey59fTwvZm9udD57e2VuZH19Cnt7LSBpZiBlcSAuIDJ9fTxmb250IGNvbG9yPVwid2FybmluZ1wiPnt7Ln19PC9mb250Pnt7ZW5kfX0Ke3stIGlmIGVxIC4gM319PGZvbnQgY29sb3I9XCJjb21tZW50XCI+e3sufX08L2ZvbnQ+e3tlbmR9fQp7ey0gZW5kfX1dKHt7JFN0YXR1c1VSTH19KfCfkYh7e3ByaW50ZiAiJS4yZiIgLlJlc3VsdC5Db21wbGV0ZX19Cnt7LSBpZiBlcSAuUmVzdWx0LlN0YXR1cyAxIH19CioqTWF4TGFnRGV0YWlsczoqKgp7ey0gd2l0aCAuUmVzdWx0Lk1heGxhZ319Cnt7LlRvcGljfX1be3suU3RhdHVzLlN0cmluZ319XSgpe3twcmludGYgIiUuMmYiIC5Db21wbGV0ZX19Clx0UGFydGl0aW9uPXt7LlBhcnRpdGlvbn198J+TiExhZz17ey5DdXJyZW50TGFnfX17e2lmIC5Pd25lcn194oS577iPe3suT3duZXJ9fS97e2VuZH19e3tpZiAuQ2xpZW50SUR9fXt7LkNsaWVudElEfX17e2VuZH19Cnt7LSBlbmR9fQp7ey0gZW5kfX0Ke3stICRUb3RhbEVycm9ycyA6PSBsZW4gLlJlc3VsdC5QYXJ0aXRpb25zfX0Ke3stIGlmICRUb3RhbEVycm9yc319CiMjIyA8Zm9udCBjb2xvcj1cImNvbW1lbnRcIj57eyRUb3RhbEVycm9yc319IHBhcnRpdGlvbnMgaGF2ZSBwcm9ibGVtcyhNYXhMYWc9e3suUmVzdWx0Lk1heGxhZ3xtYXhsYWd9fSk8L2ZvbnQ+Cj4qKkNvdW50UGFydGl0aW9uczoqKgp7ey0gcmFuZ2UgJGssJHYgOj0gLlJlc3VsdC5QYXJ0aXRpb25zfHBhcnRpdGlvbmNvdW50c319Cnt7LSBpZiBuZSAkdiAwfX1cblx0e3ska319PXt7JHZ9fXt7ZW5kfX0Ke3stIGVuZH19CioqVG9waWNzQnlTdGF0dXM6KioKe3stIHJhbmdlICRrLCR2IDo9IC5SZXN1bHQuUGFydGl0aW9uc3x0b3BpY3NieXN0YXR1c319Clx0e3ska319PXt7JHZ9fQp7ey0gZW5kfX0KKipQYXJ0aXRpb25EZXRhaWxzOioqCnt7LSByYW5nZSAuUmVzdWx0LlBhcnRpdGlvbnN9fQp7ey5Ub3BpY319W3t7LlN0YXR1cy5TdHJpbmd9fV0oKXt7cHJpbnRmICIlLjJmIiAuQ29tcGxldGV9fQpcdFBhcnRpdGlvbj17ey5QYXJ0aXRpb259ffCfk4hMYWc9e3suQ3VycmVudExhZ319e3tpZiAuT3duZXJ9feKEue+4j3t7Lk93bmVyfX0ve3tlbmR9fXt7aWYgLkNsaWVudElEfX17ey5DbGllbnRJRH19e3tlbmR9fQp7ey0gZW5kfX0Ke3stIGVuZH19CiIKfX0K | base64 -d)
EOF
}
webhook_tmpl

configuring() {
  cat <<EOF >burrow.yaml
#autoreload
client-profile:
$(if [ -n "$CLUSTERS_VERSION" ]; then
    for kv in $CLUSTERS_VERSION; do
      cluster=${kv%=*}
      version=${kv#*=}
      echo "  $cluster:
    client-id: burrow-lagchecker
    kafka-version: $version"
    done
  fi)
cluster:
$(if [ -n "$CLUSTERS" ]; then
    for kv in $CLUSTERS; do
      cluster=${kv%=*}
      servers=$(
        IFS=,
        for server in ${kv#*=}; do echo "      - $server"; done
      )
      echo "  $cluster:
    class-name: kafka$(for kv in $CLUSTERS_VERSION; do
        if [ "${kv%=*}" = "$cluster" ]; then
          echo "
    client-profile: $cluster"
          break
        fi
      done)
    topic-refresh: ${TOPIC_REFRESH:-60}
    offset-refresh: ${OFFSET_REFRESH:-10}
    servers:
$servers
    groups-reaper-refresh: ${GROUPS_REAPER_REFRESH:-300}"
    done
  fi)
consumer:
$(if [ -n "$CONSUMERS" ]; then
    for kv in $CONSUMERS; do
      cluster=${kv%%=*}
      cluster_zk=${kv#*=}
      if [ "${cluster_zk%=*}" != "${cluster_zk}" ]; then
        zk_path=${cluster_zk##*=}
      fi
      servers=$(
        IFS=,
        for server in ${cluster_zk%%=*}; do echo "      - $server"; done
      )
      echo "  $cluster:
    class-name: kafka_zk$(for kv in $CLUSTERS_VERSION; do
        if [ "${kv%=*}" = "$cluster" ]; then
          echo "
    client-profile: $cluster"
          break
        fi
      done)$(if [ -n "$zk_path" ]; then
        echo "
    zookeeper-path: $zk_path"
      fi)
    cluster: $cluster
    servers:
$servers
    start-latest: ${START_LATEST:-true}"
    done
  else
    for kv in $CLUSTERS; do
      cluster=${kv%=*}
      servers=$(
        IFS=,
        for server in ${kv#*=}; do echo "      - $server"; done
      )
      echo "  $cluster:
    class-name: kafka$(for kv in $CLUSTERS_VERSION; do
        if [ "${kv%=*}" = "$cluster" ]; then
          echo "
    client-profile: $cluster"
          break
        fi
      done)
    cluster: $cluster
    servers:
$servers
    start-latest: ${START_LATEST:-true}"
    done
  fi)
evaluator:
  default:
    allowed-lag: ${ALLOWED_LAG:-5}
    class-name: caching
    minimum-complete: ${MINIMUM_COMPLETE:-0.3}
httpserver:
  default:
    address: :8000
notifier:
$(if [ -n "$DINGTALK_TOKENS" ] || [ -n "$WECOM_TOKENS" ]; then
    for kv in $DINGTALK_TOKENS; do
      cluster=${kv%%=*}
      tokens=${kv#*=}
      (
        IFS=,
        for kv in $tokens; do
          webhook=${kv%=*}
          token=${kv#*=}
          webhook_url="$DINGTALK_API$token"
          echo "  dingtalk.$cluster.$webhook:
    class-name: http
    cluster: $cluster
    group-denylist: ^burrow-.*$
    threshold: ${SEND_THRESHOLD:-2}
    template-close: $DINGTALK_TMPL
    template-open: $DINGTALK_TMPL
    url-close: $webhook_url
    url-open: $webhook_url
    send-close: ${SEND_CLOSE:-true}
    send-once: ${SEND_ONCE:-true}"
        done
      )
    done
    for kv in $WECOM_TOKENS; do
      cluster=${kv%%=*}
      tokens=${kv#*=}
      (
        IFS=,
        for kv in $tokens; do
          webhook=${kv%=*}
          token=${kv#*=}
          webhook_url="$WECOM_API$token"
          echo "  wecom.$cluster.$webhook:
    class-name: http
    cluster: $cluster
    group-denylist: ^burrow-.*$
    threshold: ${SEND_THRESHOLD:-2}
    template-close: $WECOM_TMPL
    template-open: $WECOM_TMPL
    url-close: $webhook_url
    url-open: $webhook_url
    send-close: ${SEND_CLOSE:-true}
    send-once: ${SEND_ONCE:-true}"
        done
      )
    done
  fi)
storage:
  default:
    class-name: inmemory
    min-distance: ${MIN_DISTANCE:-1}
zookeeper:
  servers:
$(
    IFS=,
    for server in ${ZK_ENDPOINTS:-127.0.0.1:2181}; do echo "    - $server"; done
  )
EOF
}
configuring
