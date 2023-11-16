FROM node:lts-bullseye AS install
ARG COMMIT_ID=25e120e6e5647e9281c35d85c2efe20512f3f3d4
ARG TARGETPLATFORM
WORKDIR /vpk
RUN set -ex && \
  git clone https://github.com/k8svisual/vpk . && \
  git reset --hard $COMMIT_ID && \
  npm install -g npm@latest && \
  npm install && \
  npm audit fix --force && \
  wget -SOkubectl https://dl.k8s.io/release/v1.29.15/bin/$TARGETPLATFORM/kubectl && chmod a+x kubectl && \
  echo $COMMIT_ID >commit_id && \
  rm -rf .git

FROM node:lts-bullseye-slim
ENV TZ=Asia/ShangHai
VOLUME /vpk/cluster
WORKDIR /vpk
COPY --from=install --chown=node:node /vpk/kubectl /bin
COPY --from=install --chown=node:node /vpk .
EXPOSE 4200
CMD ["node", "server.js", "-p", "4200", "-c", "yes"]