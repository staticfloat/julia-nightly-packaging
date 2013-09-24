#!/bin/bash
set -e
set -x

# This script invoked by a cron job every X hours
# This script functions best when the following are installed:
#   git, python (with the "requests" module installed, for Travis-CI API), playtpus (must be in path)
#
# You must install Winston from source for proper bundling. This script assumes you have copied the
#  contents of the relevant .julia/ directory to the directory pointed to by $JULIA_PKGDIR below.


JULIA_GIT_BRANCH="master"
if [[ ! -z "$1" ]]; then
    JULIA_GIT_BRANCH="$1"
fi

# define variables
JULIA_GIT_URL="https://github.com/JuliaLang/julia.git"
BUILD_DIR=~/tmp/julia-packaging

# This is the directory where my .julia directory is stored with cairo, tk, etc... all precompiled and ready
export JULIA_PKGDIR=$(echo ~)/julia_packaging_home/

# cd to the location of this script
cd $(dirname $0)
ORIG_DIR=$(pwd)

# Check if we've been downloaded as a git directory.  If so, update ourselves!
if [[ -d .git ]]; then
        git pull
fi

# Store everything in a temp dir
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Checkout julia
if test ! -d julia-${JULIA_GIT_BRANCH}; then
        git clone ${JULIA_GIT_URL} julia-${JULIA_GIT_BRANCH}
fi

# Go into our checkout of JULIA_GIT_URL
cd julia-${JULIA_GIT_BRANCH}
rm -rf deps/libuv deps/Rmath # This is the most common failure mode
git submodule update
git reset --hard
git checkout ${JULIA_GIT_BRANCH}
git fetch
git reset --hard origin/${JULIA_GIT_BRANCH}

# Find the last commit that passed a Travis build
LAST_GOOD_COMMIT=$(${ORIG_DIR}/get_last_good_commit.py)
if [ -z "$LAST_GOOD_COMMIT" ]; then
        echo "ERROR: No good commits detected, going with HEAD!"
        LAST_GOOD_COMMIT="HEAD"
fi

git checkout -B ${JULIA_GIT_BRANCH} $LAST_GOOD_COMMIT
if [[ "$?" != 0 ]]; then
        echo "Couldn't checkout last good commit, going with master/HEAD!"
        git checkout master
fi

# Build julia
make cleanall
make USE_SYSTEM_BLAS=1 USE_BLAS64=0 VERBOSE=1 testall

# Begin packaging steps
cd contrib/mac/app

# Check that Winston is installed
if [ ! -d $JULIA_PKGDIR/Winston ]; then
    echo "ERROR: Winston not installed to ${JULIA_PKGDIR}/; remedy this and try again!" 1>&2
    exit -1
fi

# Make special packaging makefile
make USE_SYSTEM_BLAS=1 USE_BLAS64=0

DMG_TARGET="julia-0.2-unstable.dmg"

if [[ "$JULIA_GIT_BRANCH" != "master" ]]; then
    DMG_TARGET="julia-0.2-$(basename $JULIA_GIT_BRANCH)-unstable.dmg"
fi

# We force its name to be julia-0.2-unstable.dmg
mv *.dmg "${BUILD_DIR}/$DMG_TARGET"

# Upload .dmg file
${BUILD_DIR}/julia-${JULIA_GIT_BRANCH}/julia ${ORIG_DIR}/upload_binary.jl ${BUILD_DIR}/$DMG_TARGET /bin/osx/x64/0.2/$DMG_TARGET

echo "Packaged .dmg available at ${BUILD_DIR}/${DMG_TARGET}, and uploaded to AWS"
