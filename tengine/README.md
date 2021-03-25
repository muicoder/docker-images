selfSSL
===
### nginx-CA
```
openssl genrsa -out ca.key -passout pass:cacaca 4096
openssl req -x509 -new -days 3650 -key ca.key -out ca.crt -subj "/C=CN/ST=ST/L=L/O=O/OU=OU/CN=nginx.rootCA" -passin pass:cacaca
```
### nginx-server
```
openssl genrsa -out server.key -passout pass:server 4096
openssl req -new -days 3650 -key server.key -out server.csr -subj "/C=CN/ST=ST/L=L/O=O/OU=OU/CN=localhost" -passin pass:server
openssl x509 -req -days 3650 -CA ca.crt -CAkey ca.key -CAserial server.srl -CAcreateserial -in server.csr -out server.crt -passin pass:cacaca
```
### nginx-client
```
openssl genrsa -out client.key -passout pass:client 4096
openssl req -new -days 3650 -key client.key -out client.csr -subj "/C=CN/ST=ST/L=L/O=O/OU=OU/CN=client" -passin pass:client
openssl x509 -req -days 3650 -CA ca.crt -CAkey ca.key -CAserial client.srl -CAcreateserial -in client.csr -out client.crt -passin pass:cacaca
# pem2pfx
openssl pkcs12 -export -inkey client.key -in client.crt -name client -CAfile ca.crt -caname nginx.rootCA -chain -out client.pfx -password pass:client
```
### tomcat-CA
```
openssl genrsa -out ca.key -passout pass:cacaca 4096
openssl req -x509 -new -days 3650 -key ca.key -out ca.crt -subj "/C=CN/ST=ST/L=L/O=O/OU=OU/CN=tomcat.rootCA" -passin pass:cacaca
# crt2jks
keytool -import -noprompt -trustcacerts -alias tomcat.rootCA -file ca.crt -keystore ca.jks -storepass cacaca
```
### tomcat-server
```
openssl genrsa -out server.key -passout pass:server 4096
openssl req -new -days 3650 -key server.key -out server.csr -subj "/C=CN/ST=ST/L=L/O=O/OU=OU/CN=localhost" -passin pass:server
openssl x509 -req -days 3650 -CA ca.crt -CAkey ca.key -CAserial server.srl -CAcreateserial -in server.csr -out server.crt -passin pass:server
# pem2pfx
openssl pkcs12 -export -inkey server.key -in server.crt -name server -out server.pfx -password pass:server
# pfx2jks
keytool -importkeystore -srckeystore server.pfx -srcstoretype pkcs12 -destkeystore server.jks -srcstorepass server -deststorepass server
rm -f server.pfx
```
### tomcat-administrator
```
openssl genrsa -out administrator.key -passout pass:administrator 4096
openssl req -new -days 3650 -key administrator.key -out administrator.csr -subj "/C=CN/ST=ST/L=L/O=O/OU=OU/CN=administrator" -passin pass:administrator
openssl x509 -req -days 3650 -CA ca.crt -CAkey ca.key -CAserial administrator.srl -CAcreateserial -in administrator.csr -out administrator.crt -passin pass:cacaca
# pem2pfx
openssl pkcs12 -export -inkey administrator.key -in administrator.crt -name administrator -CAfile ca.crt -caname tomcat.rootCA -chain -out administrator.pfx -password pass:administrator
```
tomcat
===
```
    <Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"
               maxThreads="150" SSLEnabled="true" scheme="https" secure="true"
               truststoreFile="${catalina.base}/conf/ca.jks" truststorePass="cacaca"
               keystoreFile="${catalina.home}/conf/server.jks" keystorePass="server"
               clientAuth="false" sslProtocol="TLS" />
```
```
        <Valve className="org.apache.catalina.valves.RemoteIpValve"
               remoteIpHeader="x-real-ip" />
```
```
<role rolename="manager-gui"/>
<role rolename="manager-script"/>
<role rolename="manager-jmx"/>
<role rolename="admin-gui"/>
<role rolename="admin-script"/>
<user username="admin" password="tomcat" roles="manager-gui,manager-script,manager-jmx,admin-gui,admin-script"/>
</tomcat-users>
```
nginx
===
### nginx.conf
```
worker_processes  auto;
```
```
# HTTP server
    upstream tomcat_http{
        server 127.0.0.1:8080 weight=1 max_fails=2 fail_timeout=3s;
    }

# HTTPS server
    upstream tomcat_https{
        server 127.0.0.1:8443 weight=1 max_fails=2 fail_timeout=3s;
    }

location / {
    #rewrite ^ https://$server_name$request_uri? permanent;
    #return 301 https://$server_name$request_uri;
    proxy_pass $scheme://tomcat_$scheme;
    include proxy.conf;
}

#https://www.wosign.com/faq/faq2016-0307-02.htm
ssl on;

ssl_certificate     server.crt;# (证书公钥)
ssl_certificate_key server.key;# (证书私钥)

ssl_verify_client off;# 验证client证书
ssl_verify_depth 1;# client证书认证链长度,根据ca.crt设置
ssl_client_certificate ca.crt;# 签发client证书的CA证书

#http://www.cnblogs.com/daojoo/p/4179881.html
proxy_ssl_certificate     administrator.crt;# nginx与tomcat通信的证书公钥
proxy_ssl_certificate_key administrator.key;# nginx与tomcat通信的证书私钥

proxy_ssl_verify on;# 验证tomcat证书
proxy_ssl_verify_depth 1;# tomcat证书认证链长度,根据ca.crt设置
proxy_ssl_trusted_certificate ca.crt;# 签发tomcat证书的CA证书


proxy_set_header Client-Cert $ssl_client_cert;# 将客户端证书放到头中传递给后端服务器
```
### proxy.conf
```
proxy_connect_timeout 1;
proxy_redirect             off;
proxy_set_header           Host $host:$server_port;
proxy_set_header           X-Real-IP $remote_addr;
proxy_set_header           X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header           X-Forwarded-Proto $scheme;
proxy_set_header           Accept-Encoding 'gzip';
client_max_body_size       100m;
client_body_buffer_size    256k;
proxy_connect_timeout      500;
proxy_send_timeout         2000;
proxy_read_timeout         2000;
proxy_ignore_client_abort  on;

proxy_http_version          1.1;
proxy_set_header Upgrade    $http_upgrade;
proxy_set_header Connection "upgrade";

proxy_buffer_size          128k;
proxy_buffers              4 256k;
proxy_busy_buffers_size    256k;
proxy_temp_file_write_size 256k;

proxy_cookie_domain off;
proxy_cookie_path off;
```
### [Nginx 配置上更安全的 SSL & ECC 证书 & Chacha20 & Certificate Transparency](https://www.pupboss.com/nginx-add-ssl)
