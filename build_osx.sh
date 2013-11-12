#!/bin/bash
set -e
set -x

# This script invoked by a cron job every X hours
# This script functions best when the following are installed:
#   git, python (with the "requests" module installed, for Travis-CI API), playtpus (must be in path)


JULIA_GIT_BRANCH="master"
if [[ ! -z "$1" ]]; then
    JULIA_GIT_BRANCH="$1"
fi

BUILD_DIR=$(echo ~)/tmp/julia-packaging/osx
BANNER="Official http://julialang.org release"
SNOWLEOPARD=
if [[ "$2" == "sl" ]]; then
    SNOWLEOPARD=1
    extra_makevars="USE_SYSTEM_LIBUNWIND=1"
    BUILD_DIR=$(echo ~)/tmp/julia-packaging/osx10.6
    shift
fi

GIVEN_COMMIT=
if [[ ! -z "$2" ]]; then
    GIVEN_COMMIT="$2"
fi

# define variables
cd $(dirname $0)
ORIG_DIR=$(pwd)

# Check if we've been downloaded as a git directory.  If so, update ourselves!
if [[ -d .git ]]; then
        git pull
fi

# Do the gitwork to checkout the latest version of julia, clean everything up, etc...
source $ORIG_DIR/build_gitwork.sh

# Build julia
make cleanall
make USE_SYSTEM_BLAS=1 USE_BLAS64=0 VERBOSE=1 TAGGED_RELEASE_BANNER="$BANNER" $extra_makevars testall

# Begin packaging steps
cd contrib/mac/app

# Make special packaging makefile
make USE_SYSTEM_BLAS=1 USE_BLAS64=0 TAGGED_RELEASE_BANNER="$BANNER" $extra_makevars

DMG_TARGET="julia-0.2pre.dmg"
if [[ "$JULIA_GIT_BRANCH" != "master" ]]; then
    DMG_TARGET="julia-0.2pre-$(basename $JULIA_GIT_BRANCH).dmg"
fi

# If we're building a snowleopard version
if [[ "$SNOWLEOPARD" == "1" ]]; then
    DMG_TARGET="${DMG_TARGET%.*}-10.6.dmg"
fi

# We force its name to be julia-0.2pre.dmg
mv *.dmg "${BUILD_DIR}/$DMG_TARGET"

# Upload .dmg file
if [[ -z "$GIVEN_COMMIT" ]]; then
    ${BUILD_DIR}/julia-${JULIA_GIT_BRANCH}/julia ${ORIG_DIR}/upload_binary.jl ${BUILD_DIR}/$DMG_TARGET /bin/osx/x64/0.2/$DMG_TARGET

    echo "Packaged .dmg available at ${BUILD_DIR}/${DMG_TARGET}, and uploaded to AWS"
else
    echo "Packaged .dmg available at ${BUILD_DIR}/${DMG_TARGET}"
fi

# Report finished build!
if [[ "$SNOWLEOPARD" == "1" ]]; then
    ${ORIG_DIR}/report_nightly.jl "OSX 10.6" "https://s3.amazonaws.com/julialang/bin/osx/x64/0.2/julia-0.2-pre-10.6.dmg"
else
    ${ORIG_DIR}/report_nightly.jl "OSX 10.7+" "https://s3.amazonaws.com/julialang/bin/osx/x64/0.2/julia-0.2-pre.dmg"
fi
