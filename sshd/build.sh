#!/bin/sh

set -e

ver="9.6p1"

test -e "openssh-$ver" || (
	curl "https://cloudflare.cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-$ver.tar.gz" -O
	tar -xf "openssh-$ver.tar.gz"
)

cd "openssh-$ver"
grep -q sd_notify sshd.c || (
	patch -p1 <../systemd-readiness.patch
	autoreconf --force --install
)
if [ ! -e Makefile ]; then
	./configure --with-systemd --with-privsep-user=nobody \
		--prefix=/usr --sysconfdir=/etc/ssh
fi

make sshd
cp -v sshd ../../sd_sshd
