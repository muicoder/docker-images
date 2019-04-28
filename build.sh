#!/bin/bash

set -ex

HUB_USER=muicoder
HUB_PASSWPRD=$1
HUB_REPO=tomcat
HUB_VER=(6.0.53 7.0.94 8.0.53 8.5.40 9.0.19)

git clone git://github.com/$HUB_USER/$HUB_REPO; cd $HUB_REPO
docker build --build-arg TOMCAT_VERSION=${HUB_VER[2]} -t $HUB_USER/$HUB_REPO .
docker build --build-arg TOMCAT_VERSION=${HUB_VER[2]} -t $HUB_USER/$HUB_REPO:8-native -f Dockerfile.fedora.native .
docker build --build-arg TOMCAT_VERSION=${HUB_VER[2]} -t $HUB_USER/$HUB_REPO:alpine -f Dockerfile.alpine .

build () {
    if [ $1 = ${HUB_VER[3]} ]; then
        tag=${1:0:3}
    else
        tag=${1:0:1}
    fi

    if [ $2 = "Dockerfile.alpine" ]; then
        tag=$tag-alpine
        docker build -f $2 -t $HUB_USER/$HUB_REPO:$tag --build-arg TOMCAT_VERSION=$1 --cache-from $HUB_USER/$HUB_REPO:alpine .
        docker build -f $2.native -t $HUB_USER/$HUB_REPO:$tag-native --build-arg VERSION=$tag --cache-from $HUB_USER/$HUB_REPO:$tag .
    else
        docker build -f $2 -t $HUB_USER/$HUB_REPO:$tag --build-arg TOMCAT_VERSION=$1 --cache-from $HUB_USER/$HUB_REPO:latest .
        docker build -f $2.fedora.native -t $HUB_USER/$HUB_REPO:$tag-native --build-arg TOMCAT_VERSION=$1 --cache-from $HUB_USER/$HUB_REPO:8-native .
    fi
}

for d in Dockerfile Dockerfile.alpine; do
    for ver in ${HUB_VER[*]}; do
        build $ver $d
    done
done

docker login -u $HUB_USER -p $HUB_PASSWPRD
docker push $HUB_USER/$HUB_REPO
docker logout
