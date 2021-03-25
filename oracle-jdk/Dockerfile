FROM alpine AS builder

COPY _* /

RUN cat /_* | tar xzf - -C /


FROM muicoder/alpine:glibc

ARG WORK=/usr/local

ENV JAVA_HOME=$WORK/jdk
ENV JRE_HOME=$JAVA_HOME/jre
ENV CLASSPATH=.:$JAVA_HOME/lib:$JRE_HOME/lib

ENV PATH=$JAVA_HOME/bin:$JRE_HOME/bin:$PATH


COPY --from=builder /jdk* $JAVA_HOME

CMD ["java", "-version"]
