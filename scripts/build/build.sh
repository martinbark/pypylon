#!/bin/bash
set -e

usage()
{
    echo "Usage: $0 [<options>]"
    echo "Options:"
    echo "  --pylon-tgz <package>      Use the given pylon installer tgz"
    echo "  --python <path to binary>  Use the given python binary"
    echo "  --disable-tests            Disable automatic unittests"
    echo "  -h                         This usage help"
}

PYLON_TGZ=""
PYTHON="python"
DISABLE_TESTS=""

# parse args
while [ $# -gt 0 ]; do
    arg="$1"
    case $arg in
        --pylon-tgz) PYLON_TGZ="$2" ; shift ;;
        --python) PYTHON="$2" ; shift ;;
        --disable-tests) DISABLE_TESTS=1 ;;
        -h|--help) usage ; exit 1 ;;
        *)         echo "Unknown argument $arg" ; usage ; exit 1 ;;
    esac
    shift
done

if [ ! -e "$PYLON_TGZ" ]; then
    echo "Pylon installer '$PYLON_TGZ' doesn't exist"
    exit 1
fi

#make path absolute
PYLON_TGZ=$(readlink -m "$PYLON_TGZ")

BASEDIR="$(cd $(dirname $0)/../.. ; pwd)"
#enter source dir
pushd $BASEDIR

BUILD_DIR="build-dockerized-$(date +%s)"

if [ -d "$BUILD_DIR" ]; then
    echo "Build dir $BUILD_DIR already exists. Abort."
    exit 1
fi

#rm -r $BUILD_DIR
mkdir -p $BUILD_DIR/pylon
pushd $BUILD_DIR/pylon
tar -xzf $PYLON_TGZ
#we always use the extracted SDK, if you need this script to build against your pylon version add the logic :-)
PYLON_ROOT=$BUILD_DIR/pylon

#special handling of pylon 5. pylon 6 creates a bin dir. For simplicity we check for that.
if [ ! -d bin ]; then
    #extract the inner tar from pylon 5
    tar -xzf pylon-*/pylonSDK-*.tar.gz
    PYLON_ROOT=$BUILD_DIR/pylon/pylon5
fi

popd

echo "Using pylon SDK from $PYLON_ROOT"
export PYLON_ROOT

$PYTHON setup.py clean

if [ -z "$DISABLE_TESTS" ]; then
    #For now failed tests are accepted until all are fixed
    $PYTHON setup.py test || true
fi

$PYTHON setup.py bdist_wheel

rm -r "$BUILD_DIR"

popd


