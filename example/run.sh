#!/bin/bash

cd "$(dirname "$(realpath "$0")")" || exit

ansible-navigator run jharmison_redhat.oc_mirror_e2e.create
