#!/usr/bin/env python

import requests, subprocess, os, sys
builds = requests.get("https://api.travis-ci.org/builds/?owner_name=JuliaLang&name=julia").json()

# Get a list of passing builds
passing_builds = [b for b in builds if b[u'result'] == 0 and b[u'duration'] != None]

if len(passing_builds):
    # Check to make sure those builds still exist in master.
    commits_in_master = subprocess.check_output(["git", "log", "--pretty=format:%H", "-n100"])
    commits_in_master = [unicode(commit) for commit in commits_in_master.split("\n")]

    for p in passing_builds:
        sys.stderr.write('Testing ' + p[u'commit'])
        if p[u'commit'] in commits_in_master:
            print p[u'commit']
            sys.exit( 0 )
