#!/usr/bin/env bash
set -o errexit

export APP="kubernetes-dashboard"
export NAMESPACE="kubernetes-dashboard"
export CSR_NAME="$APP.$NAMESPACE.svc"

echo "... creating $APP.key"
openssl genrsa -out "$APP".key 2048

echo "... creating $APP.csr"
cat >csr.conf<<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = $APP
DNS.2 = $APP.$NAMESPACE
DNS.3 = $APP.$NAMESPACE.svc
DNS.4 = $APP.$NAMESPACE.svc.cluster.local
EOF
echo "openssl req -new -key $APP.key -subj \"/CN=$APP\" -out $APP.csr -config csr.conf"
openssl req -new -key "$APP".key -subj "/CN=$APP" -out "$APP".csr -config csr.conf

echo "... deleting existing csr, if any"
kubectl delete csr "$CSR_NAME" || :
echo "... creating kubernetes CSR object"
kubectl create -f - <<-EOF
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  groups:
  - system:authenticated
  request: $(base64 "$APP".csr | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

SECONDS=0
while true; do
  if kubectl get csr "$CSR_NAME" &> /dev/null; then
      break
  fi
  echo "... waiting for csr to be present in kubernetes"
  if [[ $SECONDS -ge 60 ]]; then
    echo "[!] timed out waiting for csr"
    exit 1
  fi
  sleep 2
done

kubectl get csr "$CSR_NAME" -o jsonpath='{.spec.groups}'
echo
kubectl certificate approve "$CSR_NAME"
kubectl get csr "$CSR_NAME" -o jsonpath='{.spec.groups}'
echo

SECONDS=0
while true; do
  serverCert=$(kubectl get csr "$CSR_NAME" -o jsonpath='{.status.certificate}')
  if [[ $serverCert != "" ]]; then
    break
  fi
  echo "... waiting for serverCert to be present in kubernetes"
  if [[ $SECONDS -ge 60 ]]; then
    echo "[!] timed out waiting for serverCert"
    exit 1
  fi
  sleep 2
done

echo "... writing $APP.pem"
echo "$serverCert" | openssl base64 -d -A -out "$APP".pem

kubectl delete csr "$CSR_NAME" || :
echo

### initial for kubernetes
[[ $APP == "kubernetes-dashboard" ]] || exit
if [[ -s recommended.yaml ]]; then
  echo "... deploying $APP"
  kubectl apply -f recommended.yaml
else
  kubectl apply -f https://github.com/kubernetes/dashboard/raw/master/aio/deploy/recommended.yaml
fi

SECONDS=0
while true; do
  appStatus=$(kubectl get -n $NAMESPACE deployment/$APP -o jsonpath='{.status.availableReplicas}')
  if ((appStatus)); then
    break
  fi
  echo "... waiting for $APP to be present in kubernetes"
  if [[ $SECONDS -ge 60 ]]; then
    echo "[!] timed out waiting for $APP"
    exit 1
  fi
  sleep 2
done

kubectl -n $NAMESPACE patch secret kubernetes-dashboard-certs --patch "$(
cat <<EOF
data:
  tls.key: $(base64 "$APP".key | tr -d '\n')
  tls.crt: $(base64 "$APP".pem | tr -d '\n')
EOF
)"

kubectl -n $NAMESPACE patch deployment kubernetes-dashboard --patch "$(
cat <<EOF
spec:
  template:
    spec:
      containers:
        - name: $APP
          args:
            - --namespace=$NAMESPACE
            - --tls-key-file=/tls.key
            - --tls-cert-file=/tls.crt
EOF
)"
