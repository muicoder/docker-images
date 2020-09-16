### Patch for Kuboard
```shell
[root@localhost ~]# ./kuboard-crack.sh kuboard.yourdomain.com
deployment.apps "kuboard" deleted
service "kuboard" deleted
serviceaccount "kuboard-user" deleted
clusterrolebinding.rbac.authorization.k8s.io "kuboard-user" deleted
serviceaccount "kuboard-viewer" deleted
clusterrolebinding.rbac.authorization.k8s.io "kuboard-viewer" deleted
deployment.extensions/kuboard patched
customresourcedefinition.apiextensions.k8s.io "kuboardlicenses.kuboard.cn" deleted
Error from server (NotFound): customresourcedefinitions.apiextensions.k8s.io "kuboardlicenses.kuboard.cn" not found

Please login http://kuboard.yourdomain.com/ to view the subscription details.

eyJhbGciOiJSUzI1NiIsImtpZCI6Ik4tV3JBejQxRWIwY2JsdlJMZ2kxcF93ZzdlQ2J4N0FzbHdWakVVVkVKdmMifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJrdWJvYXJkLXZpZXdlci10b2tlbi0ydmdnNCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJrdWJvYXJkLXZpZXdlciIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjYyNmI5ZjQzLWZlYjUtNGI2Mi05MmM4LTRmMGRlODA1MmE0NCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTprdWJvYXJkLXZpZXdlciJ9.xEa92eLbAGhMFEQSb4Twbam6F2ZtUrTXH8P45_xzPAPUQ0LIIcr0AtURvlNRJqyhzVb71yv_zP9fQbElmc7Fs9Xy1MrLkwutayINGQDCoSsb2pjEhUBfPjNEMksfxxo2M6rsMm2ZKfWk9wswvjAspOyCEZLp4gv4WK4V1x0htpbZFqEsnxYlYft2S6BcSdXfxneudTrE53-vL4hq_F9amh81r8v3--yA50_2WpoRFayZASUWuZo8dZU1VnrGUMe8196SH3ZROsX3zAS7_BRJATND0_vtU6D86bLnJur-X3l8QUES2kbhgJJEJOWxPnwI3f6V0cK4LZCKh1fhpxDibA    [token is cluster-admin]

NAME                         CREATED AT
kuboardlicenses.kuboard.cn   2020-09-01T08:08:08Z
kuboardlicense.kuboard.cn/level-2-12345678920200901 created

If you use nginx-ingress for kuboard: kubectl apply -f kuboard-ingress.yaml

```
