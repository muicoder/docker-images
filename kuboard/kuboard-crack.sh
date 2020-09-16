#!/usr/bin/env sh
set -o errexit

if [ -z "$1" ]; then
	echo "eg: $0 kuboard.yourdomain.com[:9090] [basic|xpack]"
	exit
else
	KUBOARD_AE="$1"
	KUBOARD_DOMAIN="${KUBOARD_AE%:*}"
	KUBOARD_VERSION="${2:-xpack}"
	[ "$KUBOARD_VERSION" = "basic" ] && productId="level-1"
	[ "$KUBOARD_VERSION" = "xpack" ] && productId="level-2"
	licenseId=123456789$(date +%Y%m%d)
fi

KUBOARD_NAME='kuboard'
KUBOARD_NAMESPACE='kube-system'
KUBOARD_URL='https://kuboard.cn/install-script/kuboard.yaml'


### initial for kuboard
kubectl delete -f "$KUBOARD_URL" || :
while true; do
	kubectl apply -f "$KUBOARD_URL" --wait && break
done


LICENSE_CONTENT="License-$KUBOARD_VERSION.json"
if [ -s "$LICENSE_CONTENT" ]; then
	kubectl -n $KUBOARD_NAMESPACE patch deployment $KUBOARD_NAME --patch "$(
cat <<\EOF
spec:
  revisionHistoryLimit: 1
  template:
    spec:
      terminationGracePeriodSeconds: 3
      containers:
      - name: kuboard
        lifecycle:
          postStart:
            exec:
              command:
                - sh
                - -c
                - |-
                  cd /usr/share/nginx/html/js/ && {
                  sed -i 's~\(.\)=5;if~\1=1000;if~g;s~signData\([^=]*\)=[^,]*~signData\1=true~' $(grep KEYUTIL.getKey -rl)
                  } || exit
EOF
)"
	kubectl delete crd kuboardlicenses.kuboard.cn || :
	TIMEOUT=0
	until kubectl get crd kuboardlicenses.kuboard.cn; do
		echo
		echo "Please login http://$KUBOARD_DOMAIN/ to view the subscription details."
		echo
		kubectl -n $KUBOARD_NAMESPACE get secret "$(kubectl -n $KUBOARD_NAMESPACE get sa kuboard-user -o jsonpath='{.secrets[].name}')" -o jsonpath='{.data.token}' | base64 -d
		echo "    [token is cluster-admin]"
		echo
		if [ $TIMEOUT -ge 300 ]; then
			echo "[!] timed out waiting for klcs"
			exit 1
		fi
		sleep 60
	done
	kubectl create -f - <<-EOF
	apiVersion: kuboard.cn/v1
	kind: KuboardLicense
	metadata:
	  name: "$productId-$licenseId"
	content: >-
	  $(sed "s/\(.*\)kuboardAccessEndpoint\(.*\)/\"kuboardAccessEndpoint\": \"$KUBOARD_AE\",/" "$LICENSE_CONTENT" | base64)
	signData: >-
	EOF
	cat > $KUBOARD_NAME-ingress.yaml <<-EOF
	apiVersion: extensions/v1beta1
	kind: Ingress
	metadata:
	  name: $KUBOARD_NAME
	  namespace: $KUBOARD_NAMESPACE
	  annotations:
	    k8s.kuboard.cn/displayName: $KUBOARD_NAME
	    k8s.kuboard.cn/workload: $KUBOARD_NAME
	    nginx.org/websocket-services: "$KUBOARD_NAME"
	    nginx.com/sticky-cookie-services: "serviceName=kuboard srv_id expires=1h path=/"
	spec:
	  rules:
	  - host: $KUBOARD_DOMAIN
	    http:
	      paths:
	      - path: /
	        backend:
	          serviceName: $KUBOARD_NAME
	          servicePort: http
	EOF
	echo
	echo "If you use nginx-ingress for $KUBOARD_NAME: kubectl apply -f $KUBOARD_NAME-ingress.yaml"
	echo
fi
