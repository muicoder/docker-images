# ls -lh | grep tar.gz | awk '{print $NF}'
# apache-tomcat-8.5.42.tar.gz
# jce_policy-8.tar.gz
# jdk-8u212-linux-x64.tar.gz

FROM centos:7

SHELL ["bash", "-c"]

RUN set -ex; \
    rpm --install http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum install -y tar unzip curl wget ca-certificates pwgen && \
    yum clean all && rm -rf /tmp/* /var/log/* /var/cache/yum/*

ARG WORK=/opt

ADD jdk-8*-linux-x64.tar.gz $WORK
ADD apache-tomcat-8*.tar.gz $WORK

ENV JAVA_HOME=$WORK/jdk
ENV JRE_HOME=$JAVA_HOME/jre
ENV CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib
ENV CATALINA_HOME=$WORK/tomcat \
    CATALINA_OUT=/dev/null
ENV PATH=$CATALINA_HOME/bin:$JAVA_HOME/bin:$JRE_HOME/bin:$PATH

RUN set -ex; \
    ln -s $WORK/jdk* $JAVA_HOME && \
        sed -i "s/security.provider.2=sun.security.rsa.SunRsaSign/#security.provider.2=sun.security.rsa.SunRsaSign\nsecurity.provider.2=org.bouncycastle.jce.provider.BouncyCastleProvider/" $JRE_HOME/lib/security/java.security && \
        wget -qP $JRE_HOME/lib/ext https://downloads.bouncycastle.org/java/bcprov-jdk15on-162.jar && \
        wget -qP $JRE_HOME/lib/ext https://downloads.bouncycastle.org/java/bcprov-ext-jdk15on-162.jar && \
    ln -s $WORK/apache-tomcat-* $CATALINA_HOME && \
        sed -ri 's|^#!/bin/sh$|#!/usr/bin/env bash|' $CATALINA_HOME/bin/*.sh && \
    TOMCAT_VERSION=8.5.42 && \
        wget -qP $CATALINA_HOME/lib http://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_VERSION:0:1}/v${TOMCAT_VERSION}/bin/extras/catalina-jmx-remote.jar && \
    DUMB_VERSION=1.2.2 && \
        curl -fsSL https://github.com/Yelp/dumb-init/releases/download/v$DUMB_VERSION/dumb-init_${DUMB_VERSION}_amd64 -o /sbin/dumb-init && \
    curl -fsSL https://github.com/muicoder/docker-images/raw/tomcat/entrypoint.sh -o /sbin/entrypoint.sh && \
    chmod +x /sbin/*

ADD jce_policy-8.tar.gz $JRE_HOME/lib/security

WORKDIR $CATALINA_HOME
VOLUME $CATALINA_HOME/logs

EXPOSE 8080 8443

ENTRYPOINT ["dumb-init", "entrypoint.sh"]
CMD ["catalina.sh", "run"]
