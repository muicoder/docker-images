#!/bin/bash

HUB_USER=muicoder
HUB_REPO=stf
HUB_PASSWORD=$1

VER=${2:-3.4.0}

git clone git://github.com/$HUB_USER/$HUB_REPO; cd $HUB_REPO

docker build -t muicoder/stf:master .

if [ str"$3" = str"dev" ]; then
    sed -i 's/npm prune/# npm prune/' Dockerfile
    docker build -t muicoder/stf:master-$3 --cache-from muicoder/stf:master .
    docker build -t muicoder/stf:$VER-$3 --build-arg VERSION=v$VER --cache-from muicoder/stf:master .
else
    docker build -t muicoder/stf:$VER --build-arg VERSION=v$VER --cache-from muicoder/stf:master .
    docker tag muicoder/stf:$VER muicoder/stf
fi

docker login -u $HUB_USER -p $HUB_PASSWORD
docker push $HUB_USER/$HUB_REPO
docker logout
