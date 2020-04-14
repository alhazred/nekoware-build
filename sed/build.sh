#!/usr/nekoware/bin/bash
#
# nekoware build toolset
# 2020 Alexander Eremin (alexander.r.eremin@gmail.com)
#
. ../neko.sh

PROG=sed
VER=4.8
ARCHIVE=$PROG-$VER.tar.gz
URL=https://ftp.gnu.org/gnu/sed/$ARCHIVE
DESCRIPTION="GNU sed, the Unix stream editor"

CONFIGURE_OPTS="
    --disable-dependency-tracking
"

init
get_source
patch_source
build
make_tardist
cleanup

