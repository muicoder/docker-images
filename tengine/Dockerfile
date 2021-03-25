FROM muicoder/alpine:glibc

ARG TENGINE_VERSION=2.3.3

ARG NGINX_USER=nginx

ARG CONFIG="\
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/etc/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --user=$NGINX_USER \
    --group=$NGINX_USER \
\
    --with-select_module \
    --with-poll_module \
\
    --with-threads \
\
    --with-file-aio \
\
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_xslt_module \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module \
    --with-http_geoip_module=dynamic \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_degradation_module \
    --with-http_slice_module \
    --with-http_stub_status_module \
\
    --with-mail \
    --with-mail=dynamic \
    --with-mail_ssl_module \
\
    --with-stream \
    --with-stream=dynamic \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --with-stream_geoip_module \
    --with-stream_geoip_module=dynamic \
    --with-stream_ssl_preread_module \
    --with-stream_sni \
\
    --with-compat \
"

RUN addgroup -S $NGINX_USER \
    && adduser -S -D -h /var/cache/nginx -s /sbin/nologin -G $NGINX_USER $NGINX_USER \
    && apk add --no-cache openssl-dev pcre-dev \
    && apk add --no-cache --virtual .build-deps \
        gcc \
        libc-dev \
        make \
        zlib-dev \
        linux-headers \
        curl \
        gnupg \
        libxslt-dev \
        gd-dev \
        geoip-dev \
    && mkdir -p /usr/src \
    && curl -fsSL https://github.com/alibaba/tengine/archive/${TENGINE_VERSION:-master}.tar.gz | tar -xzf - -C /usr/src \
    && cd /usr/src/tengine-*/ \
    && ./configure $CONFIG && make -j$(getconf _NPROCESSORS_ONLN) && make install \
    && mkdir /etc/nginx/conf.d/ \
    && strip /usr/sbin/nginx* \
    && strip /etc/nginx/modules/*.so \
    && rm -rf /usr/src/tengine-* \
\
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /usr/local/bin/ \
    && runDeps="$( \
        scanelf --needed --nobanner /usr/sbin/nginx /etc/nginx/modules/*.so /usr/local/bin/envsubst \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
			)" \
    && apk add --no-cache --virtual .nginx-rundeps $runDeps \
    && apk del .build-deps .gettext .nginx-rundeps \
    && curl -fsSL https://github.com/muicoder/docker-images/raw/tengine/tengine/nginx.conf -o /etc/nginx/nginx.conf \
    && curl -fsSL https://github.com/muicoder/docker-images/raw/tengine/tengine/selfSSL/nginx/server.key -o /etc/nginx/cert.key \
    && curl -fsSL https://github.com/muicoder/docker-images/raw/tengine/tengine/selfSSL/nginx/server.crt -o /etc/nginx/cert.pem

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
