#!/bin/bash
set -e

# This script invoked by a cron job every X hours
# $JULIA_HOME/contrib/bzr_daily_import.sh  > import.log
#
# This script functions best when the following are installed:
#   wget, git, bzr, dch, make, python (with the "requests" module installed) for the travis-ci API integration


# Note that in order to push to lp:~staticfloat/julianightlies/trunk, you need my GPG private key
TEAM=~staticfloat
PROJECT=julianightlies
JULIA_GIT_URL="https://github.com/JuliaLang/julia.git"
DEBIAN_GIT_URL="https://github.com/staticfloat/julia-debian.git"
JULIA_GIT_BRANCH=master
DEBIAN_GIT_BRANCH=master
BZR_BRANCH=trunk

cd $(dirname $0)
ORIG_DIR=$(pwd)

# Check if we've been downloaded as a git directory.  If so, update ourselves!
if [[ -d .git ]]; then
	git pull
fi

# Store everything in a temp dir
mkdir -p /tmp/julia-daily-packaging
cd /tmp/julia-daily-packaging

# Get the git branch
if test ! -d julia-${JULIA_GIT_BRANCH}; then
	git clone ${JULIA_GIT_URL} julia-${JULIA_GIT_BRANCH}
fi

# Get the bzr branch
if test ! -d ${BZR_BRANCH}; then
	bzr branch http://bazaar.launchpad.net/${TEAM}/${PROJECT}/${BZR_BRANCH}/
fi

# Get the debian directory
if test ! -d debian-${DEBIAN_GIT_BRANCH}; then
	git clone ${DEBIAN_GIT_URL} debian-${DEBIAN_GIT_BRANCH}
else
	cd debian-${DEBIAN_GIT_BRANCH}
	git pull
	cd ..
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
	echo "Couldn't detect best last commit, going with HEAD!"
	git checkout HEAD
fi
git reset --hard
# Make sure there's nothing laying around from forced pushes/rebases, etc...
git clean -fdx
git submodule init
git submodule update

# Hack to get around our lack of packaging of Rmath
make -C deps get-random

# Make it blaringly obvious to everyone that this is a git build when they start up Julia
COMMIT=$(git log --pretty=format:'%h' -n 1)
echo "0.2.0+git$COMMIT" > VERSION
echo "Syncing commit $COMMIT."
cd ..

# Now go into the bzr branch and copy everything over
cd ${BZR_BRANCH}
bzr pull http://bazaar.launchpad.net/${TEAM}/${PROJECT}/${BZR_BRANCH}/
rm -rf *
cp -r ../julia-${JULIA_GIT_BRANCH}/* .

# Throw the debian directory into here as well, instead of relying on launchpad
cp -r ../debian-${DEBIAN_GIT_BRANCH}/debian .

# Also, increment the current debian changelog, so we get git version tagged binaries
dch -v $(cat VERSION) -b "nightly git build"

bzr add
bzr ci -m "Manual import commit ${COMMIT} from ${JULIA_GIT_URL}/${JULIA_GIT_BRANCH}" || true
bzr push lp:${TEAM}/${PROJECT}/${BZR_BRANCH}
cd ..

rm -rf ../julia-debian-master
exit 0
