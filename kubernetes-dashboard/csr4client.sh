#!/usr/bin/env bash
set -o errexit

KUBE_USER=${1:-admin}
CA=${2:-ca.crt}

if [[ ! -s $CA ]]; then
	echo "... creating kubernetes $CA"
	kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d > "$CA"
fi

openssl req -new -SHA256 -newkey rsa:2048 -nodes -keyout "$KUBE_USER".key -out "$KUBE_USER".csr -subj "/CN=$KUBE_USER/O=system:masters"

if grep k3s <<<$(kubectl version --short | grep Server) &> /dev/null; then
	CAFILE="/var/lib/rancher/k3s/server/tls/client-ca.crt"
	CAKEY="/var/lib/rancher/k3s/server/tls/client-ca.key"
	if [ "$(id -u)" = "0" ]; then
		openssl x509 -req -in "$KUBE_USER".csr -CA "$CAFILE" -CAkey "$CAKEY" -CAcreateserial -out "$KUBE_USER".crt -days 365
	else
		echo "you must be root to run it." 
		exit
	fi
else
	CAFILE="$CA"
	echo "... deleting existing csr, if any"
	kubectl delete csr "$KUBE_USER" || :

	echo "... creating kubernetes CSR object"
	kubectl create -f - <<-EOF
	apiVersion: certificates.k8s.io/v1beta1
	kind: CertificateSigningRequest
	metadata:
	  name: $KUBE_USER
	spec:
	  request: $(base64 "$KUBE_USER".csr | tr -d '\n')
	  usages:
	  - digital signature
	  - key encipherment
	  - client auth
	EOF

	SECONDS=0
	while true; do
		if kubectl get csr "$KUBE_USER" &> /dev/null; then
				break
		fi
		echo "... waiting for csr to be present in kubernetes"
		if [[ $SECONDS -ge 60 ]]; then
			echo "[!] timed out waiting for csr"
			exit 1
		fi
		sleep 2
	done

	kubectl get csr "$KUBE_USER" -o jsonpath='{.spec.groups}'
	echo
	kubectl certificate approve "$KUBE_USER"
	kubectl get csr "$KUBE_USER" -o jsonpath='{.spec.groups}'
	echo

	SECONDS=0
	while true; do
		clientCert=$(kubectl get csr "$KUBE_USER" -o jsonpath='{.status.certificate}')
		if [[ $clientCert != "" ]]; then
			break
		fi
		echo "... waiting for serverCert to be present in kubernetes"
		if [[ $SECONDS -ge 60 ]]; then
			echo "[!] timed out waiting for serverCert"
			exit 1
		fi
		sleep 2
	done

	echo "... creating $KUBE_USER.crt"
	echo "$clientCert" | openssl base64 -d -A -out "$KUBE_USER".crt

	kubectl delete csr "$KUBE_USER" || :
fi

echo "... verifying $KUBE_USER.crt"
kubectl auth can-i '*' '*'
kubectl config set-credentials "$KUBE_USER" --certificate-authority="$CA" --client-certificate="$KUBE_USER".crt --client-key="$KUBE_USER".key --embed-certs
kubectl config set-context --current --user="$KUBE_USER"
kubectl auth can-i '*' '*'

openssl pkcs12 -export -inkey "$KUBE_USER".key -in "$KUBE_USER".crt -CAfile "$CAFILE" -chain -out "$KUBE_USER".pfx -name kubernetes-admin -password pass:k8s
