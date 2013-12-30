#!/usr/bin/env python

from launchpadlib.launchpad import Launchpad
import requests, json

lp = Launchpad.login_anonymously('ppastats', 'production')
archive = lp.people['staticfloat'].getPPAByName(name = "julianightlies")

binaries = archive.getPublishedBinaries(status='Published')
timestr = min([z['date_published'] for z in binaries.entries])

requests.post("http://status.julialang.org/put/nightly", data=json.dumps({'target':'Ubuntu', 'time':timestr}))