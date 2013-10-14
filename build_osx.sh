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
BUILD_DIR=$(echo ~)/tmp/julia-packaging/osx
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
make USE_SYSTEM_BLAS=1 USE_BLAS64=0 VERBOSE=1 testall

# Begin packaging steps
cd contrib/mac/app

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
