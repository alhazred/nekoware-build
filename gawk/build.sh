#!/usr/nekoware/bin/bash
#
# nekoware build toolset
# 2020 Alexander Eremin (alexander.r.eremin@gmail.com)
#
. ../neko.sh

PROG=gawk
VER=5.0.1
ARCHIVE=$PROG-$VER.tar.gz
URL=https://ftp.gnu.org/gnu/gawk/$ARCHIVE
DESCRIPTION="GNU awk"

init
get_source
patch_source
build
make_tardist
cleanup

