#!/bin/bash

# Download and build cctools, distributed by Apple under the APSL and the GPLv2

CCTOOLS_URL=http://www.opensource.apple.com/tarballs/cctools/cctools-829.tar.gz
APSL_URL=http://opensource.org/licenses/APSL-2.0
BUILD=/tmp/cctools-build/

if [[ -z $(which md) ]]; then
	echo "ERROR: Must have the `md` utility installed!  It is available from homebrew"
	exit -1
fi

rm -rf $BUILD
mkdir -p $BUILD
cd $BUILD

# Download and untar cctools
wget "$CCTOOLS_URL" -O- | tar zxv

cd cctools-*
make -C libstuff
make -C misc install_name_tool.NEW

# Now, bundle up the tools we want
MISC=$(pwd)/misc
mkdir -p ../bundle && cd ../bundle

cp $MISC/install_name_tool.NEW install_name_tool

# Make sure we've got licensing data alongside the binaries
echo "These programs compiled from Apple's cctools version 829, available here: $CCTOOLS_URL" > README
echo "All programs bundled are released under the APSL-2.0, available here: $APSL_URL" >> README


cd .. && tar zcf cctools_bundle.tar.gz bundle/*
echo "Bundle successfully created at ${BUILD}/cctools_bundle.tar.gz"
