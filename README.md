Tomcat
==============
Base docker image to run a Tomcat application server, with oracle server-jre8.

__one in build__
```bash
wget -qO- github.com/muicoder/docker-images/blob/tomcat/build.sh | bash -s -- $HUB_PASSWPRD
```

Available tags
--------------

```
muicoder/tomcat:latest(8.0.53)
muicoder/tomcat:alpine(8.0.53)
```

docker-library images
--------------

```
muicoder/tomcat:6   --->tomcat:6.0.53
muicoder/tomcat:6-alpine
muicoder/tomcat:7   --->tomcat:7.0.94
muicoder/tomcat:7-alpine
muicoder/tomcat:8   --->tomcat:8.0.53
muicoder/tomcat:8-alpine
muicoder/tomcat:8.5 --->tomcat:8.5.40
muicoder/tomcat:8.5-alpine
muicoder/tomcat:9   --->tomcat:9.0.19
muicoder/tomcat:9-alpine
```

Usage
-----

To run the image and bind to port :

    docker run -dP --name tomcat -p 8080:8080 muicoder/tomcat

The first time that you run your container, a new user `admin` with all privileges
will be created in Tomcat with a random password. To get the password, check the logs
of the container by running:

    docker logs tomcat | tac

You will see an output like the following:

    ========================================================================
    Please remember to change the above password as soon as possible!

        admin:UXrwD4stLZFv

    You can now connect to this Tomcat server using:
    ========================================================================

In this case, `UXrwD4stLZFv` is the password allocated to the `admin` user.

You can now login to you admin console to configure your tomcat server:

[http://127.0.0.1:8080/manager](http://127.0.0.1:8080/manager)

Setting a specific password for the admin account
-------------------------------------------------

If you want to use a preset password instead of a random generated one, you can
set the environment variable `TOMCAT_PASS` to your specific password when running the container:

    docker run -dP --name tomcat -p 8080:8080 -e TOMCAT_PASS="mypass" muicoder/tomcat

You can now test your deployment:

[http://127.0.0.1:8080](http://127.0.0.1:8080)

Environment variables
---------------------

* `CATALINA_OPTS` or `JAVA_OPTS`: set additionals java options (default empty), e.g:
>`JAVA_OPTS="-Dfile.encoding=UTF-8"`
