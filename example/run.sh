#!/bin/bash
cd "$(dirname "$(realpath "$0")")" || exit

RUNTIME=${RUNTIME:-podman}

runtime_args=(--rm -it)

# We need to run as the user to just not deal with labelling
runtime_args+=(--privileged --security-opt=label=disable)

# Uniquely identify this run's container instance
cluster_name=$(grep '^cluster_name: ' vars/scenario.yml | cut -d: -f2- | tr -d ' ')
runtime_args+=("--name=oc-mirror-e2e-$cluster_name")

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

# To be able to pass tags into the runner instance, we need this
printf '' > env/cmdline
if [ -n "${ANSIBLE_TAGS}" ]; then
    printf -- '--tags %s ' "${ANSIBLE_TAGS}" >> env/cmdline
fi
if [ -n "${ANSIBLE_SKIP_TAGS}" ]; then
    printf -- '--skip-tags %s ' "${ANSIBLE_TAGS}" >> env/cmdline
fi

# To ensure that variable selections are pulled from vars we need these
for vars_file in environment scenario ${ANSIBLE_EXTRA_VARS_FILES}; do
    if [ -f "vars/${vars_file}.yml" ]; then
        printf -- '--extra-vars "@vars/%s.yml" ' "${vars_file}" >> env/cmdline
    fi
done

# We need to save output, this is the default for the collection
runtime_args+=(
    -v "$PWD/output:/output"
)


# Runner will pull our inventory, config, and env
runtime_args+=(
    -v "$PWD:/runner"
)

playbooks="${*:-create test delete}"
set -e

for playbook in $playbooks; do
    playbook_arg=(-e "RUNNER_PLAYBOOK=jharmison_redhat.oc_mirror_e2e.$playbook")
    ${RUNTIME} run "${runtime_args[@]}" "${playbook_arg[@]}" "oc-mirror-e2e:${EE_VERSION:-latest}"
done
