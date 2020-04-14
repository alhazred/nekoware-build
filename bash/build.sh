#!/usr/nekoware/bin/bash
#
# nekoware build toolset
# 2020 Alexander Eremin (alexander.r.eremin@gmail.com)
#

. ../neko.sh

PROG=bash
VER=4.4
PATCHLEVEL=23
ARCHIVE=$PROG-$VER.tar.gz
URL=https://ftp.gnu.org/gnu/bash/$ARCHIVE
DESCRIPTION="GNU Bourne-Again shell (bash)"

CONFIGURE_OPTS="
    --localstatedir=/var
    --enable-alias
    --enable-arith-for-command
    --enable-array-variables
    --enable-bang-history
    --enable-brace-expansion
    --enable-casemod-attributes
    --enable-casemod-expansions
    --enable-command-timing
    --enable-cond-command
    --enable-cond-regexp
    --enable-coprocesses
    --enable-debugger
    --enable-directory-stack
    --enable-disabled-builtins
    --enable-dparen-arithmetic
    --enable-extended-glob
    --enable-help-builtin
    --enable-history
    --enable-job-control
    --enable-multibyte
    --enable-net-redirections
    --enable-process-substitution
    --enable-progcomp
    --enable-prompt-string-decoding
    --enable-readline
    --enable-restricted
    --enable-select
    --enable-separate-helpfiles
    --enable-single-help-strings
    --disable-strict-posix-default
    --enable-usg-echo-default
    --enable-xpg-echo-default
    --enable-mem-scramble
    --disable-profiling
    --enable-largefile
    --enable-nls
    --with-bash-malloc
    --with-curses
    --with-installed-readline=no
"

init
get_source
patch_source
build
VER=$VER.$PATCHLEVEL
make_tardist
cleanup
