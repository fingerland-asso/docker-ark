# Docker for ARK: Survival Evolved

## Features

* include [Ark Server Tools](https://github.com/FezVrasta/ark-server-tools)
* include [steamcmd](https://developer.valvesoftware.com/wiki/SteamCMD)
* ark server run as user, no root process

## Install from sources

edit the top of the `Makefile` to feet to your need.

```
make build
```

## prepare the volume
 
```
make volume
```

### run the docker

```
make run
```


## SystemD

to manage the docker using systemd:

```
make systemd-service
```

It will create the service file and an environment file.
