#!/bin/bash

set -e

if [[ "$#" != 1 ]]; then
	echo "Usage: $(basename $0) formula-version[.platform].bottle.tar.gz"
	exit -1
fi

if [[ ! -f "$1" ]]; then
	echo "ERROR: Cannot open $1 for reading!"
	exit -2;
fi

id="$(head -1 ~/.archivesecret 2>/dev/null)"
key="$(tail -1 ~/.archivesecret 2>/dev/null)"

if [[ -z "$id" || -z "$key" ]]; then
	echo "ERROR: Could not load ~/.archivesecret!"
	exit -3;
fi

# Figure out if there's a revision included:
revision=$(basename $1 | awk -F. 'function isnum(x){return(x==x+0)} { print isnum($((NF-2))) }')
if [[ "$revision" != "0" ]]; then
	revision=$(basename $1 | awk -F. '{print length($((NF-2)))}')
fi

# Try to parse out filename-version and platform.bottle.tar.gz
REGEX='^(.*)-([0-9.]+)\.([^\.]+).bottle.(([0-9]+)\.)?tar.gz'
basename=$(basename $1)
name=$(echo $basename | sed -E "s/$REGEX/\1/")
version=$(echo $basename | sed -E "s/$REGEX/\2/")
revision=$(echo $basename | sed -E "s/$REGEX/\5/")
name_version_platform=$(echo $basename | sed -E "s/$REGEX/\1-\2.\3/")
suffix=${basename:$((${#name_version_platform}+1))}

BOTTLE_SERVER="http://s3.us.archive.org/julialang"

function upload()
{
	curl --location --header "authorization: LOW $id:$key" \
		--upload-file "$1" "$2"
}

# create files for all architectures
for platform in mountain_lion lion snow_leopard; do
	echo "Uploading ${name}-${version}.$platform.$suffix..."
	upload "$1" "$BOTTLE_SERVER/bottles/${name}-${version}.$platform.$suffix"
done

echo
echo "Put this in your formula:"
echo
echo "  bottle do"
echo "    root_url '$BOTTLE_SERVER/bottles'"
echo "    cellar :any" # Let's be optimistic, lol
if [[ ! -z "$revision" ]]; then
	echo "    revision $revision"
fi

sha=$(shasum $1 | cut -d" " -f1)
for platform in mountain_lion lion snow_leopard; do
	echo "    sha1 '$sha' => :$platform"
done

echo "  end"
