FROM muicoder/alpine:jdk

ARG LOGSTASH_VERSION=7.10.2
ARG LOGSTASH_TARBALL=https://artifacts.elastic.co/downloads/logstash/logstash-$LOGSTASH_VERSION.tar.gz
ARG LOGSTASH_GPG_KEY=46095ACC8548582C1A2699A9D27D666CD88E42B4

ARG WORK=/usr/share/logstash
ENV PATH=$WORK/bin:$PATH

WORKDIR $WORK
RUN apk add --no-cache libzmq
RUN set -ex; \
	apk add --no-cache --virtual .fetch-deps \
		gnupg \
		openssl \
	; gpg_verify () { file=$1;url=$2;url_asc=$3;gpg_key=$4;wget -qO "$file" "$url";if [ "$url_asc" ]; then wget -qO "$file".asc "$url_asc";export GNUPGHOME="$(mktemp -d)";gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$gpg_key";gpg --batch --verify "$file".asc "$file";rm -rf "$GNUPGHOME" "$file".asc;fi;}; \
	if $(gpg_verify logstash.tar.gz "$LOGSTASH_TARBALL" "$LOGSTASH_TARBALL".asc $"LOGSTASH_GPG_KEY"); then \
		tar -xf logstash.tar.gz --strip-components=1 && rm logstash.tar.gz; \
	fi; \
	apk del .fetch-deps; \
addgroup -S logstash && adduser -S -G logstash logstash ; \
	chown -R logstash:logstash "$WORK"; \
curl -fsSL https://github.com/muicoder/docker-images/raw/elk/elk/logstash/entrypoint.sh -o /entrypoint.sh && \
	chmod +x /entrypoint.sh; \
	logstash -V && true

VOLUME $WORK/data

EXPOSE 5000

ENTRYPOINT ["tini", "-wv", "--", "/entrypoint.sh"]

CMD ["logstash", "-e"]
