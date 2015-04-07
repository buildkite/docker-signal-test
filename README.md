# Docker Signal Tester

Docker does not proxy through signals to running containers in tty mode.

## Setup

```
$ docker build -t docker-signal-test .
```

## Test 1: `docker run` (no `-t`) with `kill`

Shell 1:

```
$ docker run --rm=true docker-signal-test ./signal_printer.sh
Waiting for a signal...
```

Shell 2:

```
$ docker ps
CONTAINER ID        IMAGE                       COMMAND                CREATED             STATUS              PORTS               NAMES
9650d1f6535d        docker-signal-test:latest   "./signal_printer.sh   31 seconds ago      Up 30 seconds                           romantic_pasteur    
$ ps | grep 'docker run'
45470 ttys003    0:00.17 docker run --rm=true docker-signal-test ./signal_printer.sh
$ kill -s TERM 45470
```

Shell 1 outputs...

```
Waiting for a signal...
Received SIGTERM
Exiting...
$
```

:thumbsup:

## Test 2: `docker run -t` with `docker kill`

Shell 1:

```
$ docker run -t --rm=true docker-signal-test ./signal_printer.sh
Waiting for a signal...
```

Shell 2:

```
$ docker ps
CONTAINER ID        IMAGE                       COMMAND                CREATED             STATUS              PORTS               NAMES
e8f5c658052b        docker-signal-test:latest   "./signal_printer.sh   41 seconds ago      Up 40 seconds                           romantic_shockley   
$ docker kill -s SIGTERM e8f5c658052b
```

Shell 1 outputs...

```
Waiting for a signal...
Received SIGTERM
Exiting...
$
```

:thumbsup:

## Test 3: `docker run -t` with `kill`

Shell 1:

```
$ docker run -t --rm=true docker-signal-test ./signal_printer.sh
Waiting for a signal...
```

Shell 2:

```
$ docker ps
CONTAINER ID        IMAGE                       COMMAND                CREATED              STATUS              PORTS               NAMES
17ccb9eeeb36        docker-signal-test:latest   "./signal_printer.sh   About a minute ago   Up About a minute                       sick_banach         
$ ps | grep 'docker run'
44420 ttys003    0:00.17 docker run -t --rm=true docker-signal-test ./signal_printer.sh
$ kill -s TERM 44420
```

Shell 1 outputs...

```
Waiting for a signal...
$
```

Shell 2 shows Docker is still running:

```
$ docker ps
CONTAINER ID        IMAGE                       COMMAND                CREATED              STATUS              PORTS               NAMES
17ccb9eeeb36        docker-signal-test:latest   "./signal_printer.sh   About a minute ago   Up About a minute                       sick_banach         
```

:thumbsdown:

This is no surprise really, because `docker run --help` says this:

```
  --sig-proxy=true           Proxy received signals to the process (non-TTY mode only). SIGCHLD, SIGSTOP, and SIGKILL are not proxied.
```

## In Summary

You can only send signals to the docker process, and have them passed to the inner process, if the container is running in non-tty mode (`-T` with `docker-compose run`, or without the `-t` for `docker run`).

If you run in tty mode you need to send signals using `docker kill -s SIGNAME`.
