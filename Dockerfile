FROM ubuntu:16.04

ARG DUMB_VERSION=1.2.0

ENV DEBIAN_FRONTEND=noninteractive

RUN useradd --system \
      --create-home \
      --shell /usr/sbin/nologin \
      stf-build && \
    useradd --system \
      --create-home \
      --shell /usr/sbin/nologin \
      stf && \
    apt-get -qqy update && \
    apt-get -qqy install curl wget unzip python build-essential && \
        curl -fsSL deb.nodesource.com/setup_7.x | bash && \
        apt-get -qqy install nodejs && npm install -g node-gyp && \
    apt-get -qqy install libzmq3-dev libprotobuf-dev git graphicsmagick yasm && \
    apt-get clean && \
    curl -fsSL github.com/Yelp/dumb-init/releases/download/v$DUMB_VERSION/dumb-init_${DUMB_VERSION}_amd64 -o /sbin/dumb-init && chmod +x /sbin/dumb-init && \
    cd ~ ; ls -A | xargs -t rm -rf && \
    rm -rf /tmp/* /var/cache/apt/* /var/lib/apt/lists/* /var/log/*

ARG VERSION=master

RUN wget -qO- github.com/openstf/stf/archive/$VERSION.tar.gz | tar -xzf - && \
        mv stf-* app && \
    wget -qO- github.com/muicoder/stf/archive/master.tar.gz | tar -xzf - && \
        mv stf-*/stf.*.po app/res/common/lang/po && \
        mv stf-*/stf.*.json app/res/common/lang/translations && \
        rm -rfv stf-* && \
    chown -R stf-build:stf-build /app

USER stf-build

ENV PATH=$PATH:/app/bin:/app/node_modules/.bin

WORKDIR /app
RUN npm install && \
    bower cache clean ; npm cache clean && \
    npm prune --production && \
    cd ~ ; ls -A | xargs -t rm -rf && \
    rm -rf /tmp/*

USER stf

EXPOSE 3000

ENTRYPOINT ["dumb-init"]
CMD ["stf", "--help"]
