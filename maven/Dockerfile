FROM muicoder/alpine:jdk

ARG MAVEN_VERSION=3.6.3

ENV PATH=$PATH:/apache-maven-$MAVEN_VERSION/bin

RUN curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /
