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

# Find out where we live
cd $(dirname $0)
ORIG_DIR=$(pwd)

# Check if we've been downloaded as a git directory.  If so, update ourselves!
if [[ -d .git ]]; then
        git pull
fi

# We make 32 and 64-bit builds
for ARCH in win32 win64; do
	BUILD_DIR=$(echo ~)/tmp/julia-packaging/$ARCH

	# Do the gitwork to checkout the latest version of julia, clean everything up, etc...
	$ORIG_DIR/build_gitwork.sh

	export PATH=$(echo ~)/cross-$ARCH/bin:$PATH
	makevars="DEFAULT_REPL=basic"
	if [[ "$ARCH" == "win64" ]]; then
		makevars="$makevars XC_HOST=x86_64-w64-mingw"
	else
		makevars="$makevars XC_HOST=i686-w64-mingw32"
	fi

	make $makevars
	make $makevars win-extras
	make $makevars dist
done
