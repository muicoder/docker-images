### CertificateSigningRequest for Client
```shell
[root@localhost ~]$ ./csr4client.sh
... creating kubernetes ca.crt
Generating a 2048 bit RSA private key
................+++
...+++
writing new private key to 'admin.key'
-----
... deleting existing csr, if any
Error from server (NotFound): certificatesigningrequests.certificates.k8s.io "admin" not found
... creating kubernetes CSR object
certificatesigningrequest.certificates.k8s.io/admin created
certificatesigningrequest.certificates.k8s.io/admin approved
... creating admin.pem
certificatesigningrequest.certificates.k8s.io "admin" deleted
... verifying admin.pem
yes
User "admin" set.
```

### CertificateSigningRequest for Server
```shell
[root@localhost ~]$ ./csr4server.sh
... creating kubernetes-dashboard.key
Generating RSA private key, 2048 bit long modulus
.......................+++
..........................+++
e is 65537 (0x10001)
... creating kubernetes-dashboard.csr
openssl req -new -key kubernetes-dashboard.key -subj "/CN=kubernetes-dashboard" -out kubernetes-dashboard.csr -config csr.conf
... deleting existing csr, if any
Error from server (NotFound): certificatesigningrequests.certificates.k8s.io "kubernetes-dashboard.kubernetes-dashboard.svc" not found
... creating kubernetes CSR object
certificatesigningrequest.certificates.k8s.io/kubernetes-dashboard.kubernetes-dashboard.svc created
certificatesigningrequest.certificates.k8s.io/kubernetes-dashboard.kubernetes-dashboard.svc approved
... writing kubernetes-dashboard.pem
certificatesigningrequest.certificates.k8s.io "kubernetes-dashboard.kubernetes-dashboard.svc" deleted

... deploying kubernetes-dashboard
namespace/kubernetes-dashboard created
serviceaccount/kubernetes-dashboard created
service/kubernetes-dashboard created
secret/kubernetes-dashboard-certs created
secret/kubernetes-dashboard-csrf created
secret/kubernetes-dashboard-key-holder created
configmap/kubernetes-dashboard-settings created
role.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrole.rbac.authorization.k8s.io/kubernetes-dashboard created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
deployment.apps/kubernetes-dashboard created
service/dashboard-metrics-scraper created
deployment.apps/dashboard-metrics-scraper created
... waiting for kubernetes-dashboard to be present in kubernetes
... waiting for kubernetes-dashboard to be present in kubernetes
... waiting for kubernetes-dashboard to be present in kubernetes
secret "kubernetes-dashboard-certs" deleted
secret/kubernetes-dashboard-certs created
deployment.apps/kubernetes-dashboard patched
```
