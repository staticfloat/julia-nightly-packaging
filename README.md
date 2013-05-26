julia-nightlty-packaging
=========

Scripts to package up nightly builds of Julia.  Currently supports two platofrms; OSX and Ubuntu.

OSX
===
Set `build_osx.sh` to run regularly in crontab. It will download latest git master of this repository, check with Travis to find the latest successful julia build (via `get_last_good_commit.py`), then build and test said commit. It will then patch the platypus file accordingly, install Winston and copy it over, create a `.app` with Platypus and package it up into a `.dmg`.


Ubuntu
======
Set `build_ubuntu.sh` to run regularly in crontab. It will download latest git master of this repository, check with Travis to find the latest successful julia build (via `get_last_good_commit.py`), then pushes said build to launchpad servers for compilation
