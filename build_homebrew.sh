#!/bin/bash

# This script invoked by a cron job every X hours
# This script functions best when the following are installed and on the system path:
#   brew, julia (+ Request package)

set -x
if [[ -z "$1" ]]; then
	VERSION="--HEAD"
fi

# Find out where we live
cd $(dirname $0)
ORIG_DIR=$(pwd)

# redirect to log file
set -e
LOG_FILE=$(echo ~)/tmp/julia-packaging/homebrew_build.log
echo "" > $LOG_FILE
exec >  >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

# Print out the date
date

# function to upload our log to AWS
function upload_log {
    echo "Uploading log file $LOG_FILE..."
    ${ORIG_DIR}/upload_binary.jl $LOG_FILE logs/Homebrew.log
}

# Make SURE that this gets called, even if we die out
trap upload_log EXIT

# First, uninstall julia from Homebrew
brew rm --force julia

# Update, just in case there's been a new version released
brew update

# Next, install the version we're asking for
brew install -v $VERSION julia

# Run tests!
brew test -v $VERSION julia

# Grab the current commit
JULIA_COMMIT=$(julia -e 'println(Base.GIT_VERSION_INFO.commit_short)')

# Eliminate the * from the end of the short commit, if it exists
if [[ "${JULIA_COMMIT: -1}" == "*" ]]; then
    JULIA_COMMIT="${JULIA_COMMIT%?}"
fi

# Report back to the mothership
${ORIG_DIR}/report_nightly.jl Homebrew ${JULIA_COMMIT} " "
