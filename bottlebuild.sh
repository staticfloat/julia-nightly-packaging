#!/bin/bash

# This script is used to rebuild the bottle (and all dependencies) of the input arguments
# It will output the bottles to /tmp/bottles/, but if a bottle for a dependency or the argument already exists, it will not be rebuilt

if [[ -z "$1" ]]; then
	base=`basename $0`
	echo "Usage: $base <formula>"
	exit 1
fi

# This is where the bottles are output to
BOTTLE_DIR=/tmp/bottles

brew=$(which brew)
deps=$($brew deps -n $1)
deps="$deps $1"
mkdir -p $BOTTLE_DIR
pushd $BOTTLE_DIR >/dev/null

for dep in $deps; do
	base=$(basename $dep)
	if [[ -z $(ls $BOTTLE_DIR/$base*.tar.gz 2>/dev/null) ]]; then
		$brew rm $base
		echo $brew install --build-bottle $dep
		$brew install --build-bottle $dep
		if [[ "$?" != "0" ]]; then
			echo "Install failed, aborting..."
			exit 1
		fi
		$brew bottle $dep
	fi
done
popd > /dev/null

echo "done"
