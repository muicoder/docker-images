#!/bin/bash
set -o errexit

defaultPort=80
SERVICE=${1?Please input serviceName:servicePort.}
serviceName=${SERVICE%%:*}
servicePort=${SERVICE##*:}
if [[ -z $servicePort ]] || [[ $servicePort == $SERVICE ]]; then
  servicePort=$defaultPort
fi
# echo "serviceName: $serviceName"
# echo "servicePort: $servicePort"
DOMAIN=${2?Please input DOMAIN.}
KEY_FILE='tls-ingress.key'
CSR_NAME='tls-csr-ingress' # kubernetes CSR object: tls-csr-ingress

if [ -s "$KEY_FILE" ]; then
  echo "... using $KEY_FILE"
else
    echo "... creating $KEY_FILE"
    openssl genrsa -out "$KEY_FILE" 2048
fi

#[start] create: tls-$serviceName-ingress
kubectl delete secret tls-$serviceName-ingress || :
CERT_FILE=${KEY_FILE%%.*}.crt
if [ -s "$CERT_FILE" ]; then
  openssl x509 -text -noout -in $CERT_FILE | grep CN
else
cat >csr.conf<<-EOF
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
DNS.1 = $DOMAIN
DNS.2 = $serviceName
EOF


openssl req -new -config csr.conf -key "$KEY_FILE" -subj "/CN=$DOMAIN" -out "$DOMAIN".csr

kubectl delete csr "$CSR_NAME" || :
echo "... creating kubernetes CSR object"
kubectl create -f - <<-EOF
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: $CSR_NAME
spec:
  groups:
  - system:authenticateds
  request: $(base64 "$DOMAIN".csr | tr -d '\n')
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
echo
kubectl get csr "$CSR_NAME" -o jsonpath='{.spec.groups}'
echo

SECONDS=0
while true; do
  serverCert=$(kubectl get csr $CSR_NAME -o jsonpath='{.status.certificate}')
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

echo "... writing $DOMAIN.pem"
echo "$serverCert" | openssl base64 -d -A -out "$DOMAIN".pem
CERT_FILE=$DOMAIN.pem

kubectl delete csr "$CSR_NAME" || :
echo

fi
#[end]# create: tls-$serviceName-ingress
kubectl create secret tls --key $KEY_FILE --cert $CERT_FILE tls-$serviceName-ingress

[ -s "$DOMAIN".yaml ] || cat >"$DOMAIN".yaml <<-EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
  name: $serviceName
spec:
  rules:
  - host: $DOMAIN
    http:
      paths:
      - backend:
          serviceName: $serviceName
          servicePort: $servicePort
        path: /
  tls:
  - hosts:
    - $DOMAIN
    secretName: tls-$serviceName-ingress
EOF
kubectl config view --minify --raw | grep certificate-authority-data | awk '{print $NF}' | base64 -d | tee ca.crt
