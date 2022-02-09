#!/bin/bash

curl -sk https://127.0.0.1:8443/api/v1/superuser/registrystatus \
    | /usr/local/bin/healthcheck.py \
    && exit 0 \
    || exit 1
