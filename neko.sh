#!/usr/nekoware/bin/bash
#
# nekoware build toolset
# 2020 Alexander Eremin (alexander.r.eremin@gmail.com)
#

PATH=/usr/nekoware/bin:$PATH
export PATH

NEKOBUILDER=
NEKOBUILDERCONTACT=

PREFIX="/usr/nekoware"
CONFIGURE_CMD="./configure --prefix=$PREFIX"
SRCDIR=$PWD/`dirname $0`
PATCHDIR=patches
TMPDIR=/tmp
 
init() {
    [ -z "$BUILDDIR" ] && BUILDDIR=$PROG-$VER
    [ -z "$PROTO" ] && PROTO=$TMPDIR/$BUILDDIR/NEKO_PROTO
    DISTDIR=$TMPDIR/$BUILDDIR/NEKO_DIST 
    NPROG="neko_$PROG"
    VERSION=$(getversion)
    PLAT=$(uname -m)
    CPU=$(hinv -t cpu | awk '{ print tolower($3) }' | head -1)
} 

extract() {
    echo "==== Extarcting $1"
    case "$1" in
        (*.tar.gz|*.tgz) tar zxvf "$1" ;;
        (*.tar.bz2|*.tbz|*.tbz2) tar xvjf "$1" ;;
        (*.tar.xz|*.txz)
                tar --xz -xvf "$1" \
		    || xzcat "$1" | tar xvf - ;;
        (*.tar) tar xvf "$1" ;;
        (*.gz) gunzip "$1" ;;
        (*.bz2) bunzip2 "$1" ;;
        (*.xz) unxz "$1" ;;
        (*)   tar -xvf $file $* ;;
    esac
}

get_source() {
    pushd $TMPDIR >/dev/null
    echo "==== Downloading $URL"
    wget --no-check-certificate $URL || exit 1
    echo "==== Extracting archive"
    extract $ARCHIVE || exit 1
    mkdir -p $PROTO
    popd >/dev/null
}

patch_source() {
    echo "==== Checking for patches"
    if [ ! -d "$SRCDIR/$PATCHDIR" ]; then
        echo "==== No patches found"
    else
        echo "==== Applying patches"
	pushd $TMPDIR/$BUILDDIR >/dev/null
	for file in $(ls $SRCDIR/$PATCHDIR); do
		patch -t -N -p0 < $SRCDIR/$PATCHDIR/$file
        done
        popd > /dev/null
    fi
}

build() {
    pushd $TMPDIR/$BUILDDIR >/dev/null
    echo "==== Building $PROG"
    # gcc by default
    export CC=/usr/nekoware/gcc-4.7/bin/gcc
    export CXX=/usr/nekoware/gcc-4.7/bin/g++
    export CFLAGS="-O3 -march=$CPU -fomit-frame-pointer -fno-math-errno -fno-rounding-math -fno-signaling-nans -fgcse-sm -fgcse-las -fipa-pta -ftree-loop-linear -ftree-loop-im -fivopts -fno-keep-static-consts -fno-exceptions -freorder-blocks-and-partition -fgraphite-identity -floop-block"
    export CXXFLAGS="-O3 -march=$CPU -fomit-frame-pointer -fno-math-errno -fno-rounding-math -fno-signaling-nans -fgcse-sm -fgcse-las -fipa-pta -ftree-loop-linear -ftree-loop-im -fivopts -fno-keep-static-consts -fno-exceptions -freorder-blocks-and-partition -fgraphite-identity -floop-block -fpermissive"
    export CPPFLAGS='-I/usr/nekoware/include -I/usr/nekoware/include/glib-2.0 -I/usr/nekoware/gcc-4.7/include/c++/4.7.1'
    export LDFLAGS='-L/usr/nekoware/lib  -Wl,-rpath -Wl,/usr/nekoware/lib'

    # define COMPILER=MIPSpro if needed
    if [ "$COMPILER" == "MIPSpro" ]; then 
        export CC=c99
        export CFLAGS="-O3 -mips4 -I/usr/nekoware/include -TARG:platform=$PLAT:proc=$CPU"
        export CXXFLAGS=$CFLAGS
        export CPPFLAGS='-I/usr/nekoware/include -I/usr/include'
        export CXX=CC
        export F77=f77
        export LDFLAGS='-L/usr/nekoware/lib -rpath /usr/nekoware/lib'
        export LD_LIBRARY_PATH='/usr/nekoware/lib'
        export LD_LIBRARYN32_PATH='/usr/nekoware/lib'
        export LD_LIBRARY64_PATH='/usr/nekoware/lib64'
    fi 
    export MANPATH=/usr/nekoware/man:$MANPATH
    export GNUMAKE='/usr/nekoware/bin/make'
    export PKG_CONFIG=/usr/nekoware/bin/pkg-config
    export PKG_CONFIG_PATH='/usr/nekoware/lib/pkgconfig'
    export PKG_CONFIG_LIBDIR='/usr/nekoware/lib'

    echo "==== Using $CC compiler"
    $CONFIGURE_CMD $CONFIGURE_OPTS || exit 1 
    gmake  || exit 1
    gmake DESTDIR=$PROTO install || exit 1
    popd >/dev/null
}

get_sub() {
    case "$1" in
        bin)  SUB=sw.eoe ;;
        include) SUB=sw.hdr ;;
        lib)  SUB=sw.lib ;;
        man)  SUB=man.manpages ;;
        src)  SUB=opt.src ;;
        dist) SUB=opt.dist ;;
        share) SUB=sw.eoe;
                [[ $2 =~ man ]] && SUB=man.manpages ;;
        relnotes) SUB=opt.relnotes ;;
        *)  echo "$1 Not found"
    esac
    echo $SUB
} 

make_idb() {
    pushd $PROTO >/dev/null 
    for dir in ${PREFIX:1}/*; do
        pp="$(basename -- $dir)"
        dd=$(echo $dir)
        pushd $dd >/dev/null 
        for f in `find . ! -type d -print | sed -e 's/\.\///'` ; do
            perm=$(find $f -printf "0%m") 
            SUB=$(get_sub $pp $f) 
            echo f $perm root sys $dd/$f $dd/$f $NPROG.$SUB
        done
        popd >/dev/null
    done
    popd >/dev/null
}

bindepends() {
    if (find $PROTO -perm +0111 ! -type d ! -name "*.so*" ! -name "*.la*" -exec file {} \; | grep ELF  | cut -d: -f1 | xargs ldd | grep -v $NPROG | grep -q nekoware); then
        echo "prereq"
        echo "("
        find $PROTO -perm +0111 ! -type d ! -name "*.so*" ! -name "*.la*" -exec file {} \; | grep ELF  | cut -d: -f1 | xargs ldd | grep nekoware | awk '{print $3}' | xargs showfiles -- | grep 'f ' | awk '{print $4}' | xargs versions -M -n | grep "sw.lib"| awk '{print $2 " " $3 " maxint"}'
        echo ")"
    fi
}

libdepends() {
    if (find $PROTO -name "*.so" -exec ldd {} \; | grep -v $NPROG | grep -q nekoware); then
        echo "prereq"
        echo "("
        find $PROTO -name "*.so" -exec ldd {} \; | grep nekoware | awk '{print $3}' | xargs showfiles -- | grep 'f ' | awk '{print $4}' | xargs versions -M -n | grep "sw.lib"| awk '{print $2 " " $3 " maxint"}'
        echo ")"
    fi
}

getversion() {
    if (versions -bn $NPROG|grep -q $NPROG); then
        INSTVER=$(versions -bn $NPROG | grep $NPROG | tail -1| awk '{print $3}')
        echo $(expr $INSTVER + 1) 
    else
        echo "1"
    fi
}


make_spec() {
    echo "product $NPROG"
    echo "    id \"$PROG-$VER $DESCRIPTION\"" 
    echo "        image sw" 
    echo "        id \"software\""  
    echo "        version $VERSION" 
    echo "        order 9999" 
    echo "        subsys eoe default" 
    echo "            id \"execution only env\"" 
    echo "            replaces self" 
    bindepends  
    echo "            exp $NPROG.sw.eoe" 
    echo "        endsubsys" 
    if grep -qm 1 sw.hdr $IDB; then
        echo "        subsys hdr default" 
        echo "            id \"header\"" 
        echo "            replaces self" 
        echo "            exp $NPROG.sw.hdr" 
        echo "        endsubsys" 
    fi
    if grep -qm 1 sw.lib $IDB; then
        echo "        subsys lib default" 
        echo "            id \"shared libraries\"" 
        echo "            replaces self" 
        libdepends 
        echo "            exp $NPROG.sw.lib" 
        echo "        endsubsys" 
    fi    
    echo "    endimage" 
    if grep -qm 1 man.manpages $IDB; then
        echo "    image man" 
        echo "        id \"man pages\"" 
        echo "        version $VERSION" 
        echo "        order 9999" 
  
        echo "        subsys manpages default" 
        echo "            id \"man pages\"" 
        echo "            replaces self" 
        echo "            exp $NPROG.man.manpages" 
        echo "        endsubsys" 
        echo "    endimage" 
    fi
    echo "    image opt" 
    echo "        id \"optional software\"" 
    echo "        version $VERSION" 
    echo "        order 9999" 
    echo "        subsys relnotes" 
    echo "            id \"release notes\"" 
    echo "            replaces self" 
    echo "            exp $NPROG.opt.relnotes" 
    echo "        endsubsys" 
    echo "        subsys src" 
    echo "            id \"original source code\"" 
    echo "            replaces self" 
    echo "            exp $NPROG.opt.src"
    echo "        endsubsys" 
    echo "        subsys dist" 
    echo "            id \"distribution files\"" 
    echo "            replaces self" 
    echo "            exp $NPROG.opt.dist" 
    echo "        endsubsys" 
    if grep -qm 1 opt.patches $IDB; then
        echo "        subsys patches" 
        echo "            id \"source code patches\"" 
        echo "            replaces self" 
        echo "            exp $NPROG.opt.patches" 
        echo "        endsubsys" 
    fi
    echo "    endimage" 
    echo "endproduct" 
}

make_relnotes() {
    echo "PACKAGE NAME"
    echo "------------"
    echo "$NPROG"
    echo "\nSOURCE/VERSION"
    echo "--------------"
    echo $PROG-$VER
    echo $DESCRIPTION
    echo "\nBUILD MACHINE"
    echo "-------------" 
    echo $(uname -a) 
    echo "\nENVIRONMENT VARIABLES"
    echo "---------------------"
    echo "export CC $CC"
    echo "export CXX $CXX"
    echo "export CPP $CPP"
    echo "export CFLAGS $CFLAGS"
    echo "export CPPFLAGS $CPPFLAGS"
    echo "export CXXFLAGS $CXXFLAGS"
    echo "export LDFLAGS $LDFLAGS"
    echo "export PKG_CONFIG $PKG_CONFIG"
    echo "export PKG_CONFIG_PATH $PKG_CONFIG_PATH"
    echo "export PKG_CONFIG_LIBDIR $PKG_CONFIG_LIBDIR"
    echo "export LD_LIBRARY_PATH $LD_LIBRARY_PATH"
    echo "export LD_LIBRARYN32_PATH $LD_LIBRARYN32_PATH"
    echo "export LD_LIBRARY64_PATH $LD_LIBRARY64_PATH"
    echo "\nCONFIGURE FLAGS"
    echo "---------------"
    echo $CONFIGURE_CMD $CONFIGURE_OPTS
    echo "\nKNOWN DEPENDENCIES"
    echo "------------------"
    if (find $PROTO -perm +0111 ! -type d ! -name "*.so*" ! -name "*.la*" -exec file {} \; | grep ELF  | cut -d: -f1 | xargs ldd | grep -v $NPROG | grep -q nekoware); then
        find $PROTO -perm +0111 ! -type d ! -name "*.so*" ! -name "*.la*" -exec file {} \; | grep ELF  | cut -d: -f1 | xargs ldd | grep nekoware | awk '{print $3}' | xargs showfiles -- | grep 'f ' | awk '{print $4}' | xargs versions -n | grep "I  " | awk '{print $4}' | sed -n "{p;n;n;}"
    else
        echo "none"
    fi
    echo "\nERRORS/MISCELLANEOUS"                      
    echo   "--------------------"
    echo none 
    echo "\nPACKAGED BY"
    echo "-----------"
    echo "$NEKOBUILDER $NEKOBUILDERCONTACT"
}

make_tardist() {
    pushd $TMPDIR >/dev/null
    mkdir -p $PROTO/$PREFIX/patches
    mkdir -p $PROTO/$PREFIX/src
    mkdir -p $PROTO/$PREFIX/relnotes
    mkdir -p $PROTO/$PREFIX/dist
    
    cp $ARCHIVE $PROTO/$PREFIX/src || exit 1
    if [ -d "$SRCDIR/$PATCHDIR" ]; then
        for file in $(ls $SRCDIR/$PATCHDIR); do
            cp $SRCDIR/$PATCHDIR/$file $PROTO/$PREFIX/src
            gzip $PROTO/$PREFIX/src/$file
        done
    fi
    
    touch $PROTO/$PREFIX/dist/$NPROG.idb
    touch $PROTO/$PREFIX/dist/$NPROG.spec
    touch $PROTO/$PREFIX/relnotes/$NPROG.txt
    IDB=$TMPDIR/$BUILDDIR/$PROG-$VER.idb
    [ -f "$IDB" ] && rm -rf $IDB
    SPEC=$TMPDIR/$BUILDDIR/$PROG_$VER.spec
    [ -f "$SPEC" ] && rm -rf $SPEC
    RELNOTES=$TMPDIR/$BUILDDIR/$PROG_$VER.txt
    [ -f "$RELNOTES" ] && rm -rf $RELNOTES
    echo "==== Creating idb file"
    make_idb >> $IDB
    echo "==== Creating spec file"
    make_spec >> $SPEC
    echo "==== Creating relnotes"
    make_relnotes >> $RELNOTES
    LANG=C sort -k 5  < $IDB > $PROTO/$PREFIX/dist/$NPROG.idb \
        || exit 1
    cp $SPEC $PROTO/$PREFIX/dist/$NPROG.spec || exit 1
    cp $RELNOTES $PROTO/$PREFIX/relnotes/$NPROG.txt || exit 1
   
    mkdir $DISTDIR
    /usr/sbin/gendist -sbase $PROTO -idb  $PROTO/$PREFIX/dist/$NPROG.idb \
        -spec $PROTO/$PREFIX/dist/$NPROG.spec \
        -dist $DISTDIR -all
    cd $DISTDIR && tar cvf $SRCDIR/$NPROG-$VER.tardist *
    popd >/dev/null
    echo "==== Done"
}

cleanup() {
    rm -rf $TMPDIR/$BUILDDIR
}
