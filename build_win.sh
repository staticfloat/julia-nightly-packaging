#!/bin/bash

# This script invoked by a cron job every X hours
# This script functions best when the following are installed:
#   git, python (with the "requests" module installed, for Travis-CI API), wine, wget
#
# Note that mingw-w64-dgn must be installed per these instructions:
#   https://github.com/JuliaLang/julia/blob/master/README.windows.md
# This script assumes both the 32 and 64-bit toolchains are installed to ~/cross-win{32,64}

if [[ ! -z "$1" ]]; then
    OS="$1"
else
    echo "ERROR: Must ask for \"win32\" or \"win64\" via first arugment!" 1>&2
    exit -1
fi

if [[ "$OS" != "win32" && "$OS" != "win64" ]]; then
    echo "ERROR: can only build for \"win32\" or \"win64\"; not $1!" 1>&2
    exit -1
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

# Set our BIN_EXT
BIN_EXT="exe"

#Do the gitwork to checkout the latest version of julia, clean everything up, etc...
source $ORIG_DIR/build_gitwork.sh

export PATH=$(echo ~)/cross-$OS/bin:$PATH
makevars+=( DEFAULT_REPL=basic )
if [[ "$OS" == "win64" ]]; then
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
if [[ "$OS" == "win32" ]]; then
    PROC_OS="x86"
else
    PROC_OS="x64"
fi
if [[ -z "$GIVEN_COMMIT" ]]; then
    ${ORIG_DIR}/upload_binary.jl $EXE_SRC /bin/winnt/$PROC_OS/$VERSDIR/$TARGET
    echo "Packaged .exe available at $EXE_SRC, and uploaded to AWS"
else
    echo "Packaged .exe available at $EXE_SRC"
fi

# Report finished build!
${ORIG_DIR}/report_nightly.jl $OS "http://s3.amazonaws.com/julialang/bin/winnt/${PROC_OS}/${VERSDIR}/julia-${JULIA_VERSION}-${OS}.exe"
