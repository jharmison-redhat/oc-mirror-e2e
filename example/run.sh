#!/bin/bash

cd "$(dirname "$(realpath "$0")")" || exit

RUNTIME=${RUNTIME:-podman}

runtime_args=(--rm -it)

# We need to run as the user to just not deal with labelling
runtime_args+=(--privileged --security-opt=label=disable --name=oc-mirror-e2e)

# AWS configuration depends on exporting user variables as well as the credentials directory
cat << EOF > env/envvars
---
AWS_CONFIG_FILE: /aws/config
AWS_SHARED_CREDENTIALS_FILE: /aws/credentials
EOF
for var in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE; do
    if [ -n "${!var}" ]; then
        echo "$var: ${!var}" >> env/envvars
    fi
done
runtime_args+=(
   -v "$HOME/.aws:/aws"
)

# We need to save output, this is the default for the collection
runtime_args+=(
    -v "$PWD/output:/output"
)

# The playbook we're running
runtime_args+=(
    -e "RUNNER_PLAYBOOK=jharmison_redhat.oc_mirror_e2e.${1:-create}"
)

# Runner will pull our inventory, config, and env
runtime_args+=(
    -v "$PWD:/runner"
)

podman run "${runtime_args[@]}" "oc-mirror-e2e:${EE_VERSION:-latest}"
