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

## Test 4: `docker-compose run` with `kill`

Shell 1:

```
$ docker-compose run --rm test ./signal_printer.sh
Waiting for a signal...
```

Shell 2:

```
$ ps | grep 'docker-compose'
58623 ttys002    0:00.05 docker-compose run --rm test ./signal_printer.sh
58624 ttys002    0:00.21 docker-compose run --rm test ./signal_printer.sh
$ kill -s TERM 58623
(no output)
```

Shell 1:

```
Waiting for a signal...
Terminated: 15
$ docker ps
CONTAINER ID        IMAGE                          COMMAND                CREATED              STATUS              PORTS               NAMES
8e8c8fd3fdb7        dockersignaltest_test:latest   "./signal_printer.sh   About a minute ago   Up About a minute                       dockersignaltest_test_run_11   
$ docker logs 8e8c8fd3fdb7
Waiting for a signal...
Waiting for a signal...
$ docker kill -s TERM 8e8c8fd3fdb7
8e8c8fd3fdb7
$ docker logs 8e8c8fd3fdb7
Waiting for a signal...
Waiting for a signal...
Received SIGTERM
Exiting...
```

:thumbsdown:

## Test 4: `docker-compose run -T` with `kill`

Shell 1:

```
$ docker-compose run -T --rm test ./signal_printer.sh
(no output)
```

Shell 2:

```
$ docker ps
CONTAINER ID        IMAGE                          COMMAND                CREATED             STATUS              PORTS               NAMES
37397bad0c61        dockersignaltest_test:latest   "./signal_printer.sh   4 minutes ago       Up 4 seconds                            dockersignaltest_test_run_8   
$ docker logs 37397bad0c61
Waiting for a signal...
Waiting for a signal...
$ ps | grep docker
55273 ttys002    0:00.06 docker-compose run -T test ./signal_printer.sh
55274 ttys002    0:00.24 docker-compose run -T test ./signal_printer.sh
$ kill -s TERM 55273
```

Shell 1:

```
$ docker-compose run -T test ./signal_printer.sh
Terminated: 15
```

Shell 2:

```
$ docker ps
CONTAINER ID        IMAGE                          COMMAND                CREATED             STATUS              PORTS               NAMES
37397bad0c61        dockersignaltest_test:latest   "./signal_printer.sh   7 minutes ago       Up 3 minutes                            dockersignaltest_test_run_8
$ docker logs 37397bad0c61
Waiting for a signal...
Waiting for a signal...
$ ps | grep docker
(no output)
$ docker kill -s SIGTERM 37397bad0c61
37397bad0c61
$ docker logs 37397bad0c61
Waiting for a signal...
Waiting for a signal...
Received SIGTERM
Exiting...
```

:thumbsdown:

## In Summary

With `docker run` you can only send signals to the docker process, and have them passed to the inner process, if the container is running in non-tty mode (`-T` with `docker-compose run`, or without the `-t` for `docker run`). If you run in tty mode you need to send signals using `docker kill -s SIGNAME`.

With `docker-compose` doesn't seem to proxy signals whether started with or without the `-T` option. Also when it does receive a signal it reports the run as `Terminated` in it's output but still leaves the Docker container running, even though `docker-compose` is no longer in the process list. The only way to kill the running container is to run `docker kill`.
