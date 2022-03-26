FROM alpine:3.14

RUN set -ex; \
	apk add --no-cache bash libstdc++ coreutils ca-certificates openssl curl wget tzdata \
	tar gzip xz bzip2 p7zip zip unzip unrar \
	tini su-exec

ARG GLIBC_VERSION=2.33-r0

ENV TZ=Asia/Shanghai \
	LANG=zh_CN.UTF-8

RUN set -ex; \
	GOSU_VERSION=1.14; \
	apk add --no-cache --virtual .gosu-deps \
		ca-certificates \
		dpkg \
		gnupg \
	; \
	\
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	curl -fsSLo /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	curl -fsSLo /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
# verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	command -v gpgconf && gpgconf --kill all || :; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	\
# clean up fetch dependencies
	apk del --no-network .gosu-deps; \
	\
	chmod +x /usr/local/bin/gosu; \
# verify that the binary works
	gosu --version; \
	gosu nobody true; \
\
	curl -fsSLo /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub; \
	for pkg in glibc-$GLIBC_VERSION glibc-bin-$GLIBC_VERSION glibc-i18n-$GLIBC_VERSION; \
	do \
		curl -fsSLo ${pkg}.apk https://github.com/andyshinn/alpine-pkg-glibc/releases/download/$GLIBC_VERSION/${pkg}.apk; \
	done; apk add --no-cache *.apk; rm *.apk; \
\
	cd /usr/glibc-compat/lib && \
		ln -sf ld-*.so ld-linux-x86-64.so.2; \
		ln -sf libBrokenLocale-*.so libBrokenLocale.so; ln -sf libBrokenLocale-*.so libBrokenLocale.so.1; \
		ln -sf libanl-*.so libanl.so; ln -sf libanl-*.so libanl.so.1; \
		ln -sf libc-*.so libc.so.6; \
		ln -sf libcrypt-*.so libcrypt.so; ln -sf libcrypt-*.so libcrypt.so.1; \
		ln -sf libdl-*.so libdl.so; ln -sf libdl-*.so libdl.so.2; \
		ln -sf libm-*.so libm.so.6; \
		ln -sf libmvec-*.so libmvec.so; ln -sf libmvec-*.so libmvec.so.1; \
		ln -sf libnsl-*.so libnsl.so.1; \
		ln -sf libnss_compat-*.so libnss_compat.so; ln -sf libnss_compat-*.so libnss_compat.so.2; \
		ln -sf libnss_db-*.so libnss_db.so; ln -sf libnss_db-*.so libnss_db.so.2; \
		ln -sf libnss_dns-*.so libnss_dns.so; ln -sf libnss_dns-*.so libnss_dns.so.2; \
		ln -sf libnss_files-*.so libnss_files.so; ln -sf libnss_files-*.so libnss_files.so.2; \
		ln -sf libnss_hesiod-*.so libnss_hesiod.so; ln -sf libnss_hesiod-*.so libnss_hesiod.so.2; \
		ln -sf libpthread-*.so libpthread.so; ln -sf libpthread-*.so libpthread.so.0; \
		ln -sf libresolv-*.so libresolv.so; ln -sf libresolv-*.so libresolv.so.2; \
		ln -sf librt-*.so librt.so; ln -sf librt-*.so librt.so.1; \
		ln -sf libthread_db-*.so libthread_db.so; ln -sf libthread_db-*.so libthread_db.so.1; \
		ln -sf libutil-*.so libutil.so; ln -sf libutil-*.so libutil.so.1; \
	/usr/glibc-compat/bin/localedef --inputfile ${LANG%.*} --charmap ${LANG#*.} $LANG


ENV KUBECTL_VERSION=v1.21.4
ARG url_kubectl=https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl
ENV JQ_VERSIPN=1.6
ARG url_jq=https://github.com/stedolan/jq/releases/download/jq-$JQ_VERSIPN/jq-linux64
ENV YQ_VERSION=v4.12.1
ARG url_yq=https://github.com/mikefarah/yq/releases/download/$YQ_VERSION/yq_linux_amd64

RUN set -ex; \
    mkdir /download; \
    cd /download; \
    for url in $(env | grep url); \
    do \
        URL=$(echo $url | cut -d= -f2); \
        echo $URL; \
        if [[ ${URL##*.} = gz ]]; then \
            curl -fsSL $URL | tar -xzvf -; \
        elif [[ ${URL##*.} = zip ]]; then \
            curl -fsSL $URL -o tmp.zip; \
            unzip -q tmp.zip; \
        else \
            FILE=$(echo ${URL##*/} | cut -d_ -f1 | cut -d- -f1); \
            curl -fsSL $URL -o $FILE; \
            chmod +x $FILE; \
        fi; \
    done && find . -type f -perm /+x -exec mv -v {} /usr/local/bin \;; \
    rm -rf /download


ENTRYPOINT ["tini", "-wv", "--"]
