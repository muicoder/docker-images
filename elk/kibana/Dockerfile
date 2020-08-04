FROM muicoder/alpine:jdk

ARG KIBANA_VERSION=7.10.2
ARG KIBANA_TARBALL=https://artifacts.elastic.co/downloads/kibana/kibana-$KIBANA_VERSION-linux-x86_64.tar.gz
ARG KIBANA_GPG_KEY=46095ACC8548582C1A2699A9D27D666CD88E42B4

ARG WORK=/usr/share/kibana
ENV PATH=$WORK/bin:$PATH

WORKDIR $WORK
RUN apk add --no-cache fontconfig freetype
RUN set -ex; \
	apk add --no-cache --virtual .fetch-deps \
		gnupg \
		openssl \
	; gpg_verify () { file=$1;url=$2;url_asc=$3;gpg_key=$4;wget -qO "$file" "$url";if [ "$url_asc" ]; then wget -qO "$file".asc "$url_asc";export GNUPGHOME="$(mktemp -d)";gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$gpg_key";gpg --batch --verify "$file".asc "$file";rm -rf "$GNUPGHOME" "$file".asc;fi;}; \
	if $(gpg_verify kibana.tar.gz "$KIBANA_TARBALL" "$KIBANA_TARBALL".asc "$KIBANA_GPG_KEY"); then \
		tar -xf kibana.tar.gz --strip-components=1 && rm kibana.tar.gz; \
	fi; \
	apk del .fetch-deps; \
addgroup -S kibana && adduser -S -G kibana kibana ; \
	chown -R kibana:kibana "$WORK"; \
curl -fsSL https://github.com/muicoder/docker-images/raw/elk/elk/kibana/entrypoint.sh -o /entrypoint.sh && \
	chmod +x /entrypoint.sh; \
	kibana -V && true

VOLUME $WORK/data

EXPOSE 5601

ENTRYPOINT ["tini", "-wv", "--", "/entrypoint.sh"]

CMD ["kibana"]
