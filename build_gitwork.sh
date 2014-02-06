#!/bin/bash

# This is a common script for all the other build_*.sh scripts.  It does the 
# droll, unexciting work of checking out the latest (good) git commit, cleaning
# out old compile artifacts, etc...
#
# It needs the following environment variables set in order to work:
#  ORIG_DIR, BUILD_DIR, JULIA_GIT_BRANCH

# Ensure we can enable logging and have a good builddir
if [[ -z "$BUILD_DIR" ]]; then
	BUILD_DIR="$(echo ~)/tmp/julia-packaging/$(uname -s)"
fi

if [[ -z "$LOG_FILE" ]]; then
	LOG_FILE="$BUILD_DIR/autonamed.log"
fi
exec >$LOG_FILE 2>&1

JULIA_GIT_URL="https://github.com/JuliaLang/julia.git"
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Checkout julia
if [[ ! -d "julia-${JULIA_GIT_BRANCH}" ]]; then
    git clone ${JULIA_GIT_URL} julia-${JULIA_GIT_BRANCH}
fi

# Go into our checkout of JULIA_GIT_URL
cd julia-${JULIA_GIT_BRANCH}
rm -rf deps/libuv deps/Rmath # This is the most common failure mode
rm -f bin/sys*.ji
git submodule update
git reset --hard
git checkout ${JULIA_GIT_BRANCH}
git fetch
git reset --hard origin/${JULIA_GIT_BRANCH}

# Find the last commit that passed a Travis build
set +e
if [[ -z "$GIVEN_COMMIT" ]]; then
    LAST_GOOD_COMMIT=$(${ORIG_DIR}/get_last_good_commit.py)
    if [ -z "$LAST_GOOD_COMMIT" ]; then
        echo "ERROR: No good commits detected, going with HEAD!"
        LAST_GOOD_COMMIT="HEAD"
    fi
else
    LAST_GOOD_COMMIT="$GIVEN_COMMIT"
fi

git checkout -B ${JULIA_GIT_BRANCH} $LAST_GOOD_COMMIT
if [[ "$?" != 0 ]]; then
    echo "Couldn't checkout last good commit, going with master/HEAD!"
    git checkout master
fi
set -e

# Set commonly used variables
JULIA_VERSION=$(cat VERSION)
VERSDIR=$(cut -d. -f1-2 < VERSION)
BANNER="Official http://julialang.org/ release"
makevars=( VERBOSE=1 TAGGED_RELEASE_BANNER="$BANNER" )