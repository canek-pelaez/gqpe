#!/bin/sh

set -e # exit on errors

SRCDIR=$(dirname $0)
test -z "${SRCDIR}" && SRCDIR=.

mkdir -p m4

autoreconf -v --force --install

if [ -z "${NOCONFIGURE}" ]; then
    "${SRCDIR}"/configure $@
fi
