#!/usr/bin/env python

import json
import sys
quay = json.loads(sys.stdin.read())

if quay["status"] != "ready":
    exit(1)

exit(0)
