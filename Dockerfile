FROM centos:7

ARG WORK=/opt

SHELL ["bash", "-c"]
RUN set -ex; \
    #rpm --install http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
    yum install -y tar unzip curl wget ca-certificates pwgen && \
    yum clean all && rm -rf /tmp/* /var/log/* /var/cache/yum/*

ENV JAVA_HOME=$WORK/jdk
ENV JRE_HOME=$JAVA_HOME/jre
ENV CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib

ENV PATH=$JAVA_HOME/bin:$JRE_HOME/bin:$PATH

RUN set -ex; \
    JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=212 \
    JAVA_VERSION_BUILD=10 \
    JAVA_DOWNLOAD_ID=59066701cf1a433da9770636fbc4c9aa \
    JAVA_PACKAGE=server-jre \
    JAVA_JCE=unlimited && \
    mkdir -p $WORK && \
        curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/$JAVA_DOWNLOAD_ID/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz | tar -xzf - -C $WORK && \
        ln -s $WORK/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} $JAVA_HOME && \
        if [ "${JAVA_JCE}" == "unlimited" ]; then \
            echo "Installing Unlimited JCE policy" && \
                wget -qP $JRE_HOME/lib/ext https://downloads.bouncycastle.org/java/bcprov-jdk15on-161.jar && \
                wget -qP $JRE_HOME/lib/ext https://downloads.bouncycastle.org/java/bcprov-ext-jdk15on-161.jar && \
                sed -i "s/security.provider.2=sun.security.rsa.SunRsaSign/#security.provider.2=sun.security.rsa.SunRsaSign\nsecurity.provider.2=org.bouncycastle.jce.provider.BouncyCastleProvider/" $JRE_HOME/lib/security/java.security && \
            curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/${JAVA_VERSION_MAJOR}/jce_policy-${JAVA_VERSION_MAJOR}.zip -o /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
            unzip /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip -d /tmp && \
            mv -f /tmp/UnlimitedJCEPolicyJDK${JAVA_VERSION_MAJOR}/*.jar $JRE_HOME/lib/security; \
        fi && rm -rf /tmp/*

ARG TOMCAT_VERSION=8.0.53

ENV CATALINA_HOME=$WORK/tomcat
ENV CATALINA_OUT=/dev/null

ENV PATH=$CATALINA_HOME/bin:$PATH

SHELL ["bash", "-c"]
RUN set -ex; \
    curl -jksSL http://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_VERSION:0:1}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz | tar -xzf - -C $WORK && \
        ln -s $WORK/apache-tomcat-$TOMCAT_VERSION $CATALINA_HOME && \
        sed -ri 's|^#!/bin/sh$|#!/usr/bin/env bash|' $CATALINA_HOME/bin/*.sh && \
        wget -qP $CATALINA_HOME/lib http://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_VERSION:0:1}/v${TOMCAT_VERSION}/bin/extras/catalina-jmx-remote.jar && \
    DUMB_VERSION=1.2.0 && \
        curl -fsSL https://github.com/Yelp/dumb-init/releases/download/v$DUMB_VERSION/dumb-init_${DUMB_VERSION}_amd64 -o /sbin/dumb-init && \
    curl -fsSL https://github.com/muicoder/tomcat/raw/master/entrypoint.sh -o /sbin/entrypoint.sh && \
        chmod +x /sbin/*

WORKDIR $CATALINA_HOME
VOLUME $CATALINA_HOME/logs
EXPOSE 8080 8443

ENTRYPOINT ["dumb-init", "entrypoint.sh"]
CMD ["catalina.sh", "run"]
