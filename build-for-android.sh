#!/bin/sh
#
# in order to get external/openssl, you need to run this from the base
# of the git repo, i.e. sqlcipher/
#
#   git submodule init
#   git submodule update

CWD=`pwd`
PROJECT_ROOT=$CWD
EXTERNAL_ROOT=${PROJECT_ROOT}/external

# Android NDK setup
NDK_BASE=/usr/local/android-ndk
NDK_PLATFORM_LEVEL=8
NDK_SYSROOT=${NDK_BASE}/platforms/android-${NDK_PLATFORM_LEVEL}/arch-arm
NDK_UNAME=`uname -s | tr '[A-Z]' '[a-z]'`
NDK_TOOLCHAIN_BASE=${NDK_BASE}/toolchains/arm-linux-androideabi-4.4.3/prebuilt/${NDK_UNAME}-x86

# to use the real HOST tag, you need the latest libtool files:
# http://stackoverflow.com/questions/4594736/configure-does-not-recognize-androideabi
HOST=arm-linux-androideabi

CC="$NDK_TOOLCHAIN_BASE/bin/${HOST}-gcc --sysroot=$NDK_SYSROOT"

CFLAGS="-DSQLITE_HAS_CODEC -DHAVE_FDATASYNC=0 -Dfdatasync=fsync -I${EXTERNAL_ROOT}/openssl/include"
LDFLAGS="-L${EXTERNAL_ROOT}/openssl/libs/armeabi -lcrypto"

#------------------------------------------------------------------------------#

if [ x"$1" == x"clean" ]; then
# clean
    cd ${EXTERNAL_ROOT}/openssl
    ${NDK_BASE}/ndk-build clean
    cd ${PROJECT_ROOT}
    make clean
else # build
## build external dependencies
    cd ${EXTERNAL_ROOT}/openssl
    ${NDK_BASE}/ndk-build
    
## build sqlcipher!
    cd ${PROJECT_ROOT}
    ./configure CC="$CC" CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS" --enable-tempstore=yes --host=$HOST --enable-shared --enable-static --disable-tcl
    make

# re-link to libsqlite3 statically and to look for /data/local/libcrypto.so
    rm .libs/sqlite3
    $CC $CFLAGS -DSQLITE_OS_UNIX=1 -I. -I./src -D_HAVE_SQLITE_CONFIG_H -DNDEBUG -DSQLITE_THREADSAFE=1 -DSQLITE_THREAD_OVERRIDE_LOCK=-1 -DSQLITE_OMIT_LOAD_EXTENSION=1 -DHAVE_READLINE=0 -o .libs/sqlite3 ./src/shell.c  ${EXTERNAL_ROOT}/openssl/libs/armeabi/libcrypto.so ./.libs/libsqlite3.a -Wl,-rpath -Wl,/data/local

fi
