FROM muicoder/alpine:glibc

ENV ANDROID_HOME=/android

ENV PATH=$PATH:$ANDROID_HOME/platform-tools

RUN mkdir -pm 0750 ~/.android $ANDROID_HOME && \
    curl -fsSL https://dl.google.com/android/repository/platform-tools-latest-linux.zip -o platform-tools-latest-linux.zip && \
        unzip -q platform-tools-latest-linux.zip -d $ANDROID_HOME; rm platform-tools-latest-linux.zip && \
    curl -fsSL https://github.com/muicoder/docker-images/raw/adb/adb/entrypoint.sh -o /entrypoint.sh && \
        chmod +x /entrypoint.sh

EXPOSE 5037

ENTRYPOINT ["tini", "-wv", "--", "/entrypoint.sh"]

CMD ["adb", "-a", "-P", "5037", "server", "nodaemon"]
