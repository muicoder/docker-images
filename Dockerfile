FROM alpine:latest

RUN set -ex; \
    apk add --no-cache bash gcompat libstdc++ coreutils ca-certificates openssl curl wget tzdata \
    tar gzip xz bzip2 p7zip zip unzip \
    pwgen jq tini su-exec yq

ENV TZ=Asia/Shanghai \
	LANG=zh_CN.UTF-8

ENTRYPOINT ["tini", "-wv", "--"]
