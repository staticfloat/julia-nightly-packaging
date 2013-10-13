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
BUILD_DIR=$(echo ~)/tmp/julia-packaging/win

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

