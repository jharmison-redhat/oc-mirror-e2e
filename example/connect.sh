#!/bin/bash
cd "$(dirname "$(realpath "$0")")" || exit

if [ ! -f output/terraform/terraform.tfstate ]; then
    echo "Terraform state not found." >&2
    exit 1
fi

cluster_name=$(grep '^cluster_name: ' vars/scenario.yml | cut -d: -f2- | tr -d ' ')

tfstate=$(cat output/terraform/terraform.tfstate)

proxy=$(echo "$tfstate" | jq -r '.outputs.proxy_instance.value.hostname')
proxy_user=$(echo "$tfstate" | jq -r '.outputs.proxy_instance.value.username')
subnets=$(echo "$tfstate" | jq -r '.outputs.vpc.value|.private_subnets[], .public_subnets[]|.cidr_block' | tr '\n' ' ')

exec ../.venv/bin/sshuttle --dns -vr $proxy_user@$proxy $subnets --ssh-cmd "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i '$PWD/output/${cluster_name}_ed25519'"
