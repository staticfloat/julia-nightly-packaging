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

# Find out where we live
cd $(dirname $0)
ORIG_DIR=$(pwd)

# Check if we've been downloaded as a git directory.  If so, update ourselves!
if [[ -d .git ]]; then
    git pull
fi

# We build for 10.7+ and 10.6
for OS in "10.7+" "10.6"; do
    BUILD_DIR=$(echo ~)/tmp/julia-packaging/osx${OS}

    # Do the gitwork to checkout the latest version of julia, clean everything up, etc...
    source $ORIG_DIR/build_gitwork.sh
    JULIA_VERSION=$(cat VERSION)

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
    make $makevars

    DMG_TARGET="julia-${JULIA_VERSION}-${OS}.dmg"
    if [[ "$JULIA_GIT_BRANCH" != "master" ]]; then
        DMG_TARGET="julia-${JULIA_VERSION}-$(basename $JULIA_GIT_BRANCH)-${OS}.dmg"
    fi    

    # We force its name to be constant, rather than having gitsha's in the filename
    mv *.dmg "${BUILD_DIR}/$DMG_TARGET"

    # Upload .dmg file if we're not building a given commit
    if [[ -z "$GIVEN_COMMIT" ]]; then
        ${BUILD_DIR}/julia-${JULIA_GIT_BRANCH}/julia ${ORIG_DIR}/upload_binary.jl ${BUILD_DIR}/$DMG_TARGET /bin/osx/x64/${VERSDIR}/$DMG_TARGET
        echo "Packaged .dmg available at ${BUILD_DIR}/${DMG_TARGET}, and uploaded to AWS"
    else
        echo "Packaged .dmg available at ${BUILD_DIR}/${DMG_TARGET}"
    fi

    # Report finished build!
    AWS_URL="https://s3.amazonaws.com/julialang/bin/osx/x64/${VERSDIR}/$DMG_TARGET"
    ${ORIG_DIR}/report_nightly.jl "OSX ${OS}" $AWS_URL "$AWS_URL.log"
done