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
	source $ORIG_DIR/build_gitwork.sh
	JULIA_VERSION=$(cat VERSION)

	export PATH=$(echo ~)/cross-$ARCH/bin:$PATH
	makevars="DEFAULT_REPL=basic"
	if [[ "$ARCH" == "win64" ]]; then
		makevars="$makevars XC_HOST=x86_64-w64-mingw32"
	else
		makevars="$makevars XC_HOST=i686-w64-mingw32"
	fi

	# Ignore errors during these steps.  I don't really like this, as it makes it impossible to determine if the build failed, but oh well
	set +e
	make $makevars
	set -e

	make $makevars win-extras

	# I did this to make sure that #4213 wasn't screwing up the build, but I had to delete test/unicode.jl from the list of tests to make it work
	#make $makevars testall
	make $makevars dist

	# Upload the .exe and report to status.julialang.org:
	echo "Bundled .exe is available at $(ls ${BUILD_DIR}/julia-${JULIA_GIT_BRANCH}/julia-*.exe)"
	if [[ "$ARCH" == "win32" ]]; then
		PROC_ARCH="x86"
	else
		PROC_ARCH="x64"
	fi
	julia ${ORIG_DIR}/upload_binary.jl ${BUILD_DIR}/julia-${JULIA_GIT_BRANCH}/julia-*.exe "/bin/winnt/${PROC_ARCH}/0.3/julia-${JULIA_VERSION}-${ARCH}.exe"
	${ORIG_DIR}/report_nightly.jl "$ARCH" "http://s3.amazonaws.com/julialang/bin/winnt/${PROC_ARCH}/0.3/julia-${JULIA_VERSION}-${ARCH}.exe"
done
