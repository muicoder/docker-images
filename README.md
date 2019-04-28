Intro
=====

Running Superset in Docker container


Run
===
### docker
```
docker run -d --name superset -v superset_data:/home/superset/.superset --link redis:redis muicoder/superset
docker exec -it superset demo
```
### docker-compose
```
docker-compose --file docker-compose.yml --project-name superset up -d
docker-compose exec superset demo
```

Access
======
[localhost:8088](http://localhost:8088)

Backing up the data
-------------------

The following command will create a backup of your superset_data volume in your $PWD/superset_data.tar

```
docker run --rm -v superset_data:/data:ro -v $(pwd):/backup alpine:edge tar cvf /backup/superset_data.tar /data
```
