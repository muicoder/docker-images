Intro
=====

Running [Android Debug Bridge](https://dl.google.com/android/repository/repository-11.xml) in Docker container


Run
===
```
docker run -d --name adbd --privileged -v /dev/bus/usb:/dev/bus/usb muicoder/alpine:adb
```

Access
======
```
docker run --rm -it --network container:adbd muicoder/alpine:adb adb devices
```
