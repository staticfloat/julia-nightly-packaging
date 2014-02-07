#!/bin/bash

# This script invoked by a cron job every X hours
# This script functions best when the following are installed:
#   git, python (with the "requests" module installed, for Travis-CI API), playtpus (must be in path)

# This script builds both the 10.7+ compatible binary as well as the 10.6-compatible binary by default
# Override this by passing in either 10.7+ or 10.6 as the first argument to the script

if [[ ! -z "$1" ]]; then
    OS_LIST="$1"
    if [[ "$OS_LIST" != "osx10.7+" && "$OS_LIST" != "osx10.6" ]]; then
        echo "ERROR: can only build for \"osx10.7+\" or \"osx10.6\"; not $1!" 1>&2
        exit -1
    fi
else
    OS_LIST="osx10.7+ osx10.6"
fi

JULIA_GIT_BRANCH="master"
if [[ ! -z "$2" ]]; then
    JULIA_GIT_BRANCH="$2"
fi

# Find out where we live
cd $(dirname $0)
ORIG_DIR=$(pwd)

# Check if we've been downloaded as a git directory.  If so, update ourselves!
if [[ -d .git ]]; then
    git pull -q
fi

# We build for 10.7+ and 10.6
for OS in $OS_LIST; do
    DMG_TARGET="julia-${JULIA_VERSION}-${OS}.dmg"
    if [[ "$JULIA_GIT_BRANCH" != "master" ]]; then
        DMG_TARGET="julia-${JULIA_VERSION}-$(basename $JULIA_GIT_BRANCH)-${OS}.dmg"
    fi
    BUILD_DIR=$(echo ~)/tmp/julia-packaging/${OS}
    LOG_FILE="$BUILD_DIR/${DMG_TARGET%.*}.log"

    # Do the gitwork to checkout the latest version of julia, clean everything up, etc...
    source $ORIG_DIR/build_gitwork.sh

    # On OSX, we use Accelerate instead of OpenBLAS for now
    makevars+=( USE_SYSTEM_BLAS=1 USE_BLAS64=0 )

    # If we're compiling for snow leopard, make sure we use system libunwind
    if [[ "$OS" == "10.6" ]]; then
        makevars+=( USE_SYSTEM_LIBUNWIND=1 )
    fi

    # Build and test
    make "${makevars[@]}"
    make "${makevars[@]}" testall

    # Make special packaging makefile
    cd contrib/mac/app
    make "${makevars[@]}"

    # Upload .dmg file if we're not building a given commit
    DMG_SRC=$(ls ${BUILD_DIR}/julia-${JULIA_GIT_BRANCH}/contrib/mac/app/*.dmg)
    if [[ -z "$GIVEN_COMMIT" ]]; then
        ${ORIG_DIR}/upload_binary.jl $DMG_SRC /bin/osx/x64/$VERSDIR/$DMG_TARGET
        echo "Packaged .dmg available at $DMG_SRC, and uploaded to AWS"
    else
        echo "Packaged .dmg available at $DMG_SRC"
    fi

    # Report finished build!
    ${ORIG_DIR}/report_nightly.jl $OS "https://s3.amazonaws.com/julialang/bin/osx/x64/${VERSDIR}/$DMG_TARGET"

    # Do this in the ideal case, but it'll get called automatically no matter what
    upload_log
done
