FROM node:lts-bullseye AS install
ARG COMMIT_ID=80d539ca499d300c36ad7336ac5bddff221eba1d
WORKDIR /vpk
RUN set -ex && \
  git clone https://github.com/k8svisual/vpk . && \
  git reset --hard $COMMIT_ID && \
  npm install -g npm@latest && \
  npm install && \
  npm audit fix --force && \
  wget -qO/kubectl  https://cdn.dl.k8s.io/release/v1.29.15/bin/linux/`case $(arch) in aarch64) echo arm64;;x86_64) echo amd64;;esac`/kubectl&&chmod a+x /kubectl; \
  echo $COMMIT_ID >commit_id && \
  rm -rf .git

FROM node:lts-bullseye-slim
ENV TZ=Asia/ShangHai
VOLUME /vpk/cluster
WORKDIR /vpk
COPY --from=install --chown=node:node /kubectl /bin
COPY --from=install --chown=node:node /vpk .
EXPOSE 4200
CMD ["node", "server.js", "-p", "4200", "-c", "yes"]