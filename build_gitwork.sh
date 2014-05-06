#!/bin/bash

# This is a common script for all the other build_*.sh scripts.  It does the 
# droll, unexciting work of checking out the latest (good) git commit, cleaning
# out old compile artifacts, setting up logging, etc...
#
# It needs the following environment variables set in order to work:
#  ORIG_DIR, OS, JULIA_GIT_BRANCH

# Die on errors.  Very important.  :P
set -e

# Set our build directory
BUILD_DIR=$(echo ~)/tmp/julia-packaging/${OS}
mkdir -p $BUILD_DIR
cd $BUILD_DIR

JULIA_GIT_URL="https://github.com/JuliaLang/julia.git"
# Checkout julia
if [[ ! -d "julia-${JULIA_GIT_BRANCH}" ]]; then
    git clone ${JULIA_GIT_URL} julia-${JULIA_GIT_BRANCH}
fi

# Go into our checkout of JULIA_GIT_URL
cd julia-${JULIA_GIT_BRANCH}

# Setup some commonly-used variables
JULIA_VERSION=$(cat VERSION)
VERSDIR=$(cut -d. -f1-2 < VERSION)
BANNER="Official http://julialang.org/ release"
makevars=( VERBOSE=1 TAGGED_RELEASE_BANNER="${BANNER}" )

# Setup logging (but still output to stdout)
LOG_FILE="$BUILD_DIR/julia-${JULIA_VERSION}-${OS}.log"
function upload_log {
    echo "Uploading log file $LOG_FILE..."
    ${ORIG_DIR}/upload_binary.jl $LOG_FILE logs/$(basename $LOGFILE).log
}

# Make SURE that this gets called, even if we die out
trap upload_log EXIT

echo "" > "$LOG_FILE"
exec > "$LOG_FILE" # >(tee -a "$LOG_FILE")
exec 2>"$LOG_FILE" # >(tee -a "$LOG_FILE" >&2)
set -x
# Show the date so that the log files make a little more sense
date

# These are the most common failure modes, so clear everything out that we can
rm -rf deps/libuv deps/Rmath
rm -f usr/bin/libuv*
rm -f usr/bin/libsupport*
rm -f bin/sys*.ji
git submodule update
git reset --hard
git checkout ${JULIA_GIT_BRANCH}
git fetch
git reset --hard origin/${JULIA_GIT_BRANCH}
make -C deps clean-openlibm
make -j1 cleanall

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


# Setup the target we're going to create/upload
JULIA_COMMIT=$(git rev-parse --short HEAD)
TARGET="julia-${JULIA_VERSION}-${JULIA_COMMIT}-${OS}.$BIN_EXT"
if [[ "$JULIA_GIT_BRANCH" != "master" ]]; then
    TARGET="julia-${JULIA_VERSION}-$(basename $JULIA_GIT_BRANCH)-$(JULIA_COMMIT)-${OS}.$BIN_EXT"
fi

set -e
