#!/bin/bash
set -e

# This script invoked by a cron job every X hours
# This script functions best when the following are installed:
#   git, python (with the "requests" module installed, for Travis-CI API), playtpus (must be in path)


# define variables
JULIA_GIT_URL="https://github.com/JuliaLang/julia.git"
JULIA_GIT_BRANCH=master
BUILD_DIR=/tmp/julia-packaging
DMG_DIR=$BUILD_DIR/dmgroot


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
git pull origin master

# Find the last commit that passed a Travis build
LAST_GOOD_COMMIT=$(${ORIG_DIR}/get_last_good_commit.py)
if [ -z "$LAST_GOOD_COMMIT" ]; then
        echo "ERROR: No good commits detected!"
        exit 1
fi

git checkout $LAST_GOOD_COMMIT
if [[ "$?" != 0 ]]; then
        echo "Couldn't checkout last good commit, going with HEAD!"
        git checkout HEAD
fi
git reset --hard
# Make sure there's nothing laying around from forced pushes/rebases, etc...
#git clean -fdx

# Build julia
make OPENBLAS_DYNAMIC_ARCH=1 testall

if [[ "$?" != "0" ]]; then
    echo "ERROR: Julia did not test well, aborting!"
    exit -1
fi

# Begin packaging steps
cd contrib/mac/app

# Check that Winston is installed
if [ ! -d ~/.julia/Winston ]; then
    echo "ERROR: Winston not installed to ~/.julia; remedy this and try again!" 1>&2
    exit -1
fi

# Make special packaging makefile
make OPENBLAS_DYNAMIC_ARCH=1

# Patch and run platypus file.  Note that these paths assume platypus (the CLI interface) is in your path, and Platypus (the GUI) is installed to /Applications/
mkdir -p $DMG_DIR
sed -i -e "s_/Users/viral/julia_${BUILD_DIR}/julia-${JULIA_GIT_BRANCH}_" Julia.platypus
sed -i -e "s_/usr/local/share/platypus/_/Applications/Platypus.app/Contents/Resources/_" Julia.platypus
platypus -P Julia.platypus -y ${DMG_DIR}/Julia.app

# Build a .dmg with the .app inside
cp -f Julia.icns ${DMG_DIR}/.VolumeIcon.icns
cp -f ${ORIG_DIR}/Julia.DS_Store ${DMG_DIR}/.DS_Store
ln -fs /Applications ${DMG_DIR}/Applications
hdiutil create "${BUILD_DIR}/Julia-0.2-pre.dmg" -ov -volname "Julia" -srcfolder "$DMG_DIR"

echo "Packaged .dmg available at ${BUILD_DIR}/Julia-0.2-pre.dmg"
