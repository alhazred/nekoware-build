#!/usr/nekoware/bin/bash
#
# nekoware build toolset
# 2020 Alexander Eremin (alexander.r.eremin@gmail.com)
#
. ../neko.sh

PROG=grep
VER=3.4
ARCHIVE=$PROG-$VER.tar.xz
URL=https://ftp.gnu.org/gnu/grep/$ARCHIVE
DESCRIPTION="GNU grep utilities"

init
get_source
patch_source
build
make_tardist
cleanup

