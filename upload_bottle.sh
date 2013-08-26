#!/bin/bash

set -e

if [[ "$#" != 2 ]]; then
	echo "Usage: $(basename $0) bucket/objectprefix formula-version[.platform].bottle.tar.gz"
	exit -1
fi

if [[ ! -x "$(which aws)" ]]; then
	echo "ERROR: You must have the `aws` command line utility installed and in your PATH"
	echo "Download it from http://timkay.com/aws/"
	exit -2 # separate error codes for different errors?!  What is this?!
fi

if [[ ! -f "$2" ]]; then
	echo "ERROR: Cannot open $2 for reading!"
	exit -3;
fi

# Figure out if there's a revision included:
revision=$(basename $2 | awk -F. 'function isnum(x){return(x==x+0)} { print isnum($((NF-2))) }')
if [[ "$revision" != "0" ]]; then
	revision=$(basename $2 | awk -F. '{print length($((NF-2)))}')
fi

# Try to parse out filename-version and platform.bottle.tar.gz
REGEX='^(.*)-([0-9.]+)\.([^\.]+).bottle.(([0-9]+)\.)?tar.gz'
basename=$(basename $2)
name=$(echo $basename | sed -E "s/$REGEX/\1/")
version=$(echo $basename | sed -E "s/$REGEX/\2/")
revision=$(echo $basename | sed -E "s/$REGEX/\5/")
name_version_platform=$(echo $basename | sed -E "s/$REGEX/\1-\2.\3/")
suffix=${basename:$((${#name_version_platform}+1))}

BOTTLE_SERVER="http://$1.s3-website-us-east-1.amazonaws.com"

# Upload actual file
echo "Uploading ${name}-${version}.${suffix}..."
aws put "x-amz-acl: public-read" "$1/bottles/${name}-${version}.${suffix}" "$2"

# create links for all architectures
EMPTY_FILE=$(mktemp /tmp/uploadbottle.XXXXXX)
for platform in mountain_lion lion snow_leopard; do
	echo "Linking ${name}-${version}.$platform.$suffix..."
	aws put "x-amz-acl: public-read" "x-amz-website-redirect-location: $JULIA_BOTTLES/bottles/${name}-${version}.${suffix}" "$1/bottles/${name}-${version}.$platform.$suffix" $EMPTY_FILE
done
rm $EMPTY_FILE

echo
echo "Put this in your formula:"
echo
echo "  bottle do"
echo "    root_url '$BOTTLE_SERVER/bottles'"
echo "    cellar :any" # Let's be optimistic, lol
if [[ ! -z "$revision" ]]; then
	echo "    revision $revision"
fi

sha=$(shasum $2 | cut -d" " -f1)
for platform in mountain_lion lion snow_leopard; do
	echo "    sha1 '$sha' => :$platform"
done

echo "  end"
