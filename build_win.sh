#!/bin/bash

# This script invoked by a cron job every X hours
# This script functions best when the following are installed:
#   git, python (with the "requests" module installed, for Travis-CI API), wine, wget
#
# Note that mingw-w64-dgn must be installed per these instructions:
#   https://github.com/JuliaLang/julia/blob/master/README.windows.md
# This script assumes both the 32 and 64-bit toolchains are installed to ~/cross-win{32,64}

if [[ ! -z "$1" ]]; then
    ARCH_LIST="$1"
    if [[ "$ARCH_LIST" != "win32" && "$ARCH_LIST" != "win64" ]]; then
        echo "ERROR: can only build for \"win32\" or \"win64\"; not $1!" 1>&2
        exit -1
    fi
else
    ARCH_LIST="win32 win64"
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

# We make 32 and 64-bit builds
for ARCH in $ARCH_LIST; do
	EXE_TARGET="julia-${JULIA_VERSION}-${ARCH}.exe"
    if [[ "$JULIA_GIT_BRANCH" != "master" ]]; then
        EXE_TARGET="julia-${JULIA_VERSION}-$(basename $JULIA_GIT_BRANCH)-${ARCH}.exe"
    fi

	BUILD_DIR=$(echo ~)/tmp/julia-packaging/$ARCH
	LOG_FILE="$BUILD_DIR/${EXE_TARGET%.*}.log"

	# Do the gitwork to checkout the latest version of julia, clean everything up, etc...
	source $ORIG_DIR/build_gitwork.sh

	export PATH=$(echo ~)/cross-$ARCH/bin:$PATH
	makevars+=( DEFAULT_REPL=basic )
	if [[ "$ARCH" == "win64" ]]; then
		makevars+=( XC_HOST=x86_64-w64-mingw32 )
	else
		makevars+=( XC_HOST=i686-w64-mingw32 )
	fi

	# Ignore errors during these steps.  I don't really like this, as it makes it impossible to determine if the build failed, but oh well
	set +e
	make "${makevars[@]}"
	set -e

	make "${makevars[@]}" win-extras
	make "${makevars[@]}" dist

	# Upload the .exe and report to status.julialang.org:
	EXE_SRC=$(ls ${BUILD_DIR}/julia-${JULIA_GIT_BRANCH}/julia-*.exe)
	if [[ "$ARCH" == "win32" ]]; then
		PROC_ARCH="x86"
	else
		PROC_ARCH="x64"
	fi
	if [[ -z "$GIVEN_COMMIT" ]]; then
        ${ORIG_DIR}/upload_binary.jl $EXE_SRC /bin/winnt/$PROC_ARCH/$VERSDIR/$EXE_TARGET
        echo "Packaged .exe available at $EXE_SRC, and uploaded to AWS"
    else
        echo "Packaged .exe available at $EXE_SRC"
    fi

    # Report finished build!
	${ORIG_DIR}/report_nightly.jl $ARCH "http://s3.amazonaws.com/julialang/bin/winnt/${PROC_ARCH}/${VERSDIR}/julia-${JULIA_VERSION}-${ARCH}.exe"

	# Do this in the ideal case, but it'll get called automatically no matter what
    upload_log
done
