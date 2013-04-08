julia-bzr
=========

Scripts to upload nightly builds of Julia to launchpad
`bzr_daily_import.sh` run regularly in crontab, downloads latest git master, checks with Travis
to find the latest successful build, then pushes said build to launchpad servers for compilation
