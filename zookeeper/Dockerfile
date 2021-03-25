FROM muicoder/alpine:jdk

ARG ZOOKEEPER_VERSION=3.6.3

ENV ZOO_USER=zookeeper \
    ZOO_CONF_DIR=/zookeeper/conf \
    ZOO_DATA_DIR=/zookeeper/data \
    ZOO_DATA_LOG_DIR=/zookeeper/datalog \
    ZOO_LOG_DIR=/zookeeper/logs
# Environment variables
ENV ZOO_TICK_TIME=2000 \
    ZOO_INIT_LIMIT=5 \
    ZOO_SYNC_LIMIT=2 \
    ZOO_MAX_CLIENT_CNXNS=60 \
    ZOO_AUTOPURGE_PURGEINTERVAL=0 \
    ZOO_AUTOPURGE_SNAPRETAINCOUNT=3 \
    ZOO_4LW_COMMANDS_WHITELIST=srvr
# New in 3.5.0
ENV ZOO_STANDALONE_ENABLED=true
# New in 3.5.0
ENV ZOO_ADMINSERVER_ENABLED=true
# Advanced configuration
ENV ZOO_CFG_EXTRA="metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider metricsProvider.httpPort=7070"
ENV JVMFLAGS="-Dzookeeper.serverCnxnFactory=org.apache.zookeeper.server.NettyServerCnxnFactory"

ENV PATH=$PATH:/zookeeper-$ZOOKEEPER_VERSION/bin \
    ZOOCFGDIR=$ZOO_CONF_DIR

RUN adduser -D $ZOO_USER && \
    mkdir -p $ZOO_CONF_DIR $ZOO_DATA_DIR $ZOO_DATA_LOG_DIR $ZOO_LOG_DIR && \
    chown $ZOO_USER:$ZOO_USER $ZOO_CONF_DIR $ZOO_DATA_DIR $ZOO_DATA_LOG_DIR $ZOO_LOG_DIR && \
    apk add --no-cache su-exec && \
\
    curl -fsSL http://archive.apache.org/dist/zookeeper/zookeeper-$ZOOKEEPER_VERSION/apache-zookeeper-$ZOOKEEPER_VERSION-bin.tar.gz | tar xzf - -C / && \
        mv /apache-zookeeper-$ZOOKEEPER_VERSION-bin /zookeeper-$ZOOKEEPER_VERSION && \
        cp -av /zookeeper-$ZOOKEEPER_VERSION/conf/* $ZOO_CONF_DIR && \
    curl -fsSL https://github.com/31z4/zookeeper-docker/raw/master/$ZOOKEEPER_VERSION/docker-entrypoint.sh -o /entrypoint.sh && \
        chmod +x /entrypoint.sh

VOLUME ["$ZOO_DATA_DIR", "$ZOO_DATA_LOG_DIR"]

EXPOSE 2181 2888 3888

ENTRYPOINT ["tini", "-wv", "--", "/entrypoint.sh"]

CMD ["zkServer.sh", "start-foreground"]
