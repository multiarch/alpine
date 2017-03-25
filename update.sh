#!/bin/bash -e

# A POSIX variable
OPTIND=1 # Reset in case getopts has been used previously in the shell.

while getopts "a:v:q:u:d:" opt; do
    case "$opt" in
    a)  ARCH=$OPTARG
        ;;
    v)  VERSION=$OPTARG
        ;;
    q)  QEMU_ARCH=$OPTARG
        ;;
    u)  QEMU_VER=$OPTARG
        ;;
    d)  DOCKER_REPO=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

MIRROR=${MIRROR:-http://dl-cdn.alpinelinux.org/alpine}
REPO=$MIRROR/$VERSION/main
COMMUNITYREPO=$MIRROR/$VERSION/community
TMP=tmp
ROOTFS=rootfs

mkdir -p $TMP $ROOTFS/usr/bin

# download apk.static
if [ ! -f $TMP/sbin/apk.static ]; then
    apkv=$(curl -sSL $REPO/$ARCH/APKINDEX.tar.gz | tar -Oxz | strings |
    grep '^P:apk-tools-static$' -A1 | tail -n1 | cut -d: -f2)
    curl -sSL $REPO/$ARCH/apk-tools-static-${apkv}.apk | tar -xz -C $TMP sbin/apk.static
fi

# FIXME: register binfmt

# install qemu-user-static
if [ -n "${QEMU_ARCH}" ]; then
    if [ ! -f x86_64_qemu-${QEMU_ARCH}-static.tar.gz ]; then
        wget -N https://github.com/multiarch/qemu-user-static/releases/download/${QEMU_VER}/x86_64_qemu-${QEMU_ARCH}-static.tar.gz
    fi
    tar -xvf x86_64_qemu-${QEMU_ARCH}-static.tar.gz -C $ROOTFS/usr/bin/
fi

# create rootfs
$TMP/sbin/apk.static --repository $REPO --update-cache --allow-untrusted \
    --root $ROOTFS --initdb add alpine-base --verbose

# alter rootfs
printf '%s\n' $REPO > $ROOTFS/etc/apk/repositories
printf '%s\n' $COMMUNITYREPO >> $ROOTFS/etc/apk/repositories

# create tarball of rootfs
if [ ! -f rootfs.tar.xz ]; then
    tar --numeric-owner -C $ROOTFS -c . | xz > rootfs.tar.xz
fi

# clean rootfs
rm -f $ROOTFS/usr/bin/qemu-*-static

# create Dockerfile
cat > Dockerfile <<EOF
FROM scratch
ADD rootfs.tar.xz /

ENV ARCH=${ARCH} ALPINE_REL=${VERSION} DOCKER_REPO=${DOCKER_REPO} ALPINE_MIRROR=${MIRROR}
EOF

# add qemu-user-static binary
if [ -n "${QEMU_ARCH}" ]; then
    cat >> Dockerfile <<EOF

# Add qemu-user-static binary for amd64 builders
ADD x86_64_qemu-${QEMU_ARCH}-static.tar.gz /usr/bin
EOF
fi

# build
docker build -t "${DOCKER_REPO}:${ARCH}-${VERSION}" .
docker run --rm "${DOCKER_REPO}:${ARCH}-${VERSION}" /bin/sh -ec "echo Hello from Alpine !; set -x; uname -a; cat /etc/alpine-release"
