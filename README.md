# :earth_africa: alpine [![Build Status](https://travis-ci.org/multiarch/alpine.svg?branch=master)](https://travis-ci.org/multiarch/alpine)

![](https://raw.githubusercontent.com/multiarch/dockerfile/master/logo.jpg)

Multiarch alpine images for Docker.

* https://imagelayers.io/?images=multiarch%2Falpine:armhf-edge,multiarch%2Falpine:x86-edge,multiarch%2Falpine:x86_64-edge

* `multiarch/alpine` on [Docker Hub](https://hub.docker.com/r/multiarch/alpine/)
* [Available tags](https://hub.docker.com/r/multiarch/alpine/tags/)

## Usage

Once you need to configure binfmt-support on your Docker host.
This works locally or remotely (i.e using boot2docker or swarm).

```console
# configure binfmt-support on the Docker host (works locally or remotely, i.e: using boot2docker)
$ docker run --rm --privileged multiarch/qemu-user-static:register --reset
```

Then you can run an `armhf` image from your `x86_64` Docker host.

```console
$ docker run -it --rm multiarch/alpine:armhf-edge /bin/sh
/ # uname -a
Linux a0818570f614 4.1.13-boot2docker #1 SMP Fri Nov 20 19:05:50 UTC 2015 armv7l armv7l armv7l GNU/Linux
```

Or an `x86_64` image from your `x86_64` Docker host, directly, without qemu emulation.

```console
$ docker run -it --rm multiarch/alpine:amd64-edge /bin/sh
/ # uname -a
Linux 27fe384370c9 4.1.13-boot2docker #1 SMP Fri Nov 20 19:05:50 UTC 2015 x86_64 x86_64 x86_64 GNU/Linux
```

It also works for `x86`

```console
$ docker run -it --rm multiarch/alpine:x86-edge /bin/sh
/ # uname -a
Linux 1ae459268bce 3.13.0-36-generic #63-Ubuntu SMP Wed Sep 3 21:30:07 UTC 2014 x86_64 Linux
```

## License

MIT
