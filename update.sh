#!/bin/bash
set -e

cd "$(dirname "$BASH_SOURCE")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

repo="$(cat repo 2>/dev/null || true)"
if [ -z "$repo" ]; then
    user="$(docker info | awk -F ': ' '$1 == "Username" { print $2; exit }')"
    repo="${user:+$user/}ubuntu-core"
fi

for version in "${versions[@]}"; do
    (
	cd "$version"

	REL="$(cat version)"
	ARCH="$(cat arch)"
	qemu_arch="$(cat qemu_arch || true)"

	MIRROR=${MIRROR:-http://dl-cdn.alpinelinux.org/alpine}
	REPO=$MIRROR/$REL/main
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
	if [ -n "${qemu_arch}" ]; then
	    if [ ! -f x86_64_qemu-${qemu_arch}-static.tar.xz ]; then
		wget -N https://github.com/multiarch/qemu-user-static/releases/download/v2.5.0/x86_64_qemu-${qemu_arch}-static.tar.xz
	    fi
	    tar -xvf x86_64_qemu-${qemu_arch}-static.tar.xz -C $ROOTFS/usr/bin/
	fi

	# create rootfs
	$TMP/sbin/apk.static --repository $REPO --update-cache --allow-untrusted \
	    --root $ROOTFS --initdb add alpine-base --verbose

	# alter rootfs
	printf '%s\n' $REPO > $ROOTFS/etc/apk/repositories

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

ENV ARCH=${ARCH} ALPINE_REL=${REL} DOCKER_REPO=${repo} ALPINE_MIRROR=${MIRROR}
EOF

	# add qemu-user-static binary
	if [ -n "${qemu_arch}" ]; then
	    cat >> Dockerfile <<EOF

# Add qemu-user-static binary for amd64 builders
ADD x86_64_qemu-${qemu_arch}-static.tar.xz /usr/bin
EOF
	fi

	# build
	docker build -t "${repo}:${ARCH}-${REL}" .
	docker run --rm "${repo}:${ARCH}-${REL}" /bin/sh -ec "echo Hello from Alpine !; set -x; uname -a; cat /etc/alpine-release"

	# FIXME: tag latest
    )
done
