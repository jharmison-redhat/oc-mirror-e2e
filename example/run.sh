#!/bin/bash

cd "$(dirname "$(realpath "$0")")" || exit

podman_args=(--rm -it)

# We need to run as the user to just not deal with labelling
podman_args+=(--privileged --security-opt=label=disable)

# AWS configuration depends on exporting user variables as well as the credentials directory
podman_args+=(
    -e AWS_CONFIG_FILE=/aws/config
    -e AWS_SHARED_CREDENTIALS_FILE=/aws/credentials
    -e AWS_ACCESS_KEY_ID
    -e AWS_SECRET_ACCESS_KEY
    -e AWS_SESSION_TOKEN
    -e AWS_PROFILE
    -v "$HOME/.aws:/aws"
)

# We need to save output, this is the default for the collection
podman_args+=(
    -v ./output:/output
)

# The playbook we're running
podman_args+=(
    -e RUNNER_PLAYBOOK=jharmison_redhat.oc_mirror_e2e.create
)

# Runner will pull our inventory and config
podman_args+=(
    -v "$PWD:/runner"
)

podman run "${podman_args[@]}" "oc-mirror-e2e:${EE_VERSION:-latest}"
