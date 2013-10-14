#!/bin/bash
set -e
set -x

# This script invoked by a cron job every X hours
# This script functions best when the following are installed:
#   git, python (with the "requests" module installed, for Travis-CI API), wine, wget
#
# Note that mingw-w64-dgn must be installed per these instructions:
#   https://github.com/JuliaLang/julia/blob/master/README.windows.md
# This script assumes both the 32 and 64-bit toolchains are installed to ~/cross-win{32,64}

JULIA_GIT_BRANCH="master"
if [[ ! -z "$1" ]]; then
    JULIA_GIT_BRANCH="$1"
fi

# define variables
JULIA_GIT_URL="https://github.com/JuliaLang/julia.git"
BUILD_DIR=$(echo ~)/tmp/julia-packaging/

# cd to the location of this script
cd $(dirname $0)
ORIG_DIR=$(pwd)

# Check if we've been downloaded as a git directory.  If so, update ourselves!
if [[ -d .git ]]; then
        git pull
fi

# We make 32 and 64-bit builds
for ARCH in win32 win64; do
	mkdir -p $BUILD_DIR/$ARCH
	cd $BUILD_DIR/$ARCH

	# Checkout julia
	if test ! -d julia-${JULIA_GIT_BRANCH}; then
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

	export PATH=$(echo ~)/cross-$ARCH/bin:$PATH
	makevars="DEFAULT_REPL=basic"
	if [[ "$ARCH" == "win64" ]]; then
		makevars="$makevars XC_HOST=x86_64-w64-mingw"
	else
		makevars="$makevars XC_HOST=i686-w64-mingw32"
	fi

	make $makevars
	make $makevars dist
done
