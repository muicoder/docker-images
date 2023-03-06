FROM alpine:3.17

RUN set -ex; \
	apk add --no-cache bash libstdc++ coreutils diffutils findutils iputils procps ca-certificates openssl curl wget tzdata \
	tar gzip xz bzip2 p7zip zip unzip \
	pwgen jq tini su-exec pstree tree wrk

ARG GLIBC_VERSION=2.35-r0

ENV TZ=Asia/Shanghai \
	LANG=zh_CN.UTF-8

RUN set -e; \
	GOSU_VERSION=1.16; \
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
	done; if apk add *.apk; then ls *.apk; fi; rm *.apk; \
\
	cd /usr/glibc-compat/lib && \
		find . -type f -name "*.so.[0-9]" | while read -r so; do file=${so%.*}; if [ -s "${file##*/}" ]; then ln -sfv "${file##*/}" "$so"; fi; done; \
	/usr/glibc-compat/bin/localedef --inputfile ${LANG%.*} --charmap ${LANG#*.} $LANG

ENTRYPOINT ["tini", "-wv", "--"]
