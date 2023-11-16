ARG CACHE_IMAGE=ghcr.io/apache/flink-kubernetes-operator:main
FROM $CACHE_IMAGE AS cache
FROM quay.io/minio/mc AS mc
FROM eclipse-temurin:11-jre-jammy
ENV FLINK_HOME=/opt/flink
ENV FLINK_PLUGINS_DIR=$FLINK_HOME/plugins
ARG CACHE_VERSION=1.9-SNAPSHOT
ENV OPERATOR_JAR=flink-kubernetes-operator-$CACHE_VERSION-shaded.jar
ENV WEBHOOK_JAR=flink-kubernetes-webhook-$CACHE_VERSION-shaded.jar
ENV KUBERNETES_STANDALONE_JAR=flink-kubernetes-standalone-$CACHE_VERSION.jar

ENV OPERATOR_LIB=$FLINK_HOME/operator-lib

WORKDIR /flink-kubernetes-operator
RUN groupadd --system --gid=9999 flink && \
    useradd --system --home-dir $FLINK_HOME --uid=9999 --gid=flink flink && mkdir -p $OPERATOR_LIB

COPY --from=cache --chown=flink:flink $FLINK_HOME $FLINK_HOME
COPY --from=cache --chown=flink:flink /flink-kubernetes-operator /flink-kubernetes-operator
COPY --from=cache --chown=flink:flink /docker-entrypoint.sh /
COPY --from=mc --chown=flink:flink /usr/bin/mc /usr/bin/mc
USER flink
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["help"]
