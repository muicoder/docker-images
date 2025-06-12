FROM alpine:3

RUN set -ex; \
    apk add --no-cache bash libstdc++ coreutils ca-certificates openssl curl wget tzdata \
    tar gzip xz bzip2 p7zip zip unzip \
    pwgen jq tini su-exec yq

ENV TZ=Asia/Shanghai \
	LANG=zh_CN.UTF-8

ENTRYPOINT ["tini", "-wv", "--"]
