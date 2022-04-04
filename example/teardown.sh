#!/bin/bash

cluster=${TEARDOWN_CLUSTER:-disco}
domain=${TEARDOWN_DOMAIN:-redhat4govaws.io}

read -rsp "WARNING! This script only tears down the infrastructure that the disconnected-testbed Terraform would have provisioned and does not save your Terraform state. Are you sure you want to destroy $(printf '\e[31;1m')${cluster}.${domain}$(printf '\e[0m') infrastructure, without recovering state? Press Enter to continue, or Ctrl+C to cancel." throwaway
echo

cd "$(dirname "$(realpath "$0")")" || exit

set -x

domain_underscored=$(echo "$domain" | tr '.' '_')

awscli="$PWD/../.venv/bin/aws"

"$awscli" s3 rb --force "s3://${cluster}-${domain}-registry"

for instance in $("$awscli" ec2 describe-instances --filters Name=tag:Project,Values=disconnected-openshift-testbed Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].InstanceId" --output text); do
    for eip in $("$awscli" ec2 describe-addresses --filter Name=instance-id,Values="$instance" --query "Addresses[*].AllocationId" --output text); do
        assoc=$("$awscli" ec2 describe-addresses --filter Name=allocation-id,Values="$eip" --query "Addresses[*].AssociationId" --output text)
        "$awscli" ec2 disassociate-address --association-id "$assoc"
        "$awscli" ec2 release-address --allocation-id "$eip"
    done
    "$awscli" ec2 terminate-instances --instance-ids "$instance"
done

"$awscli" ec2 delete-key-pair --key-name "${cluster}_${domain_underscored}"

for vpc in $("$awscli" ec2 describe-vpcs --filter Name=tag:Project,Values=disconnected-openshift-testbed --query "Vpcs[*].VpcId" --output text); do
    for sg in $("$awscli" ec2 describe-security-groups --filter "Name=vpc-id,Values=$vpc" "Name=group-name,Values=registry.${cluster}.${domain}" --query "SecurityGroups[*].GroupId" --output text); do
        "$awscli" ec2 delete-security-group --group-id "$sg"
    done
    for igw in $("$awscli" ec2 describe-internet-gateways --filter "Name=attachment.vpc-id,Values=$vpc" --query "InternetGateways[*].InternetGatewayId" --output text); do
        "$awscli" ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc"
        "$awscli" ec2 delete-internet-gateway --internet-gateway-id "$igw"
    done
    for rt in $("$awscli" ec2 describe-route-tables --filter "Name=vpc-id,Values=$vpc" Name=association.main,Values=false --query "RouteTables[*].RouteTableId" --output text); do
        for assoc in $("$awscli" ec2 describe-route-tables --route-table-ids "$rt" --query "RouteTables[*].Associations[*].RouteTableAssociationId" --output text); do
            "$awscli" ec2 disassociate-route-table --association-id "$assoc"
        done
        "$awscli" ec2 delete-route-table --route-table-id "$rt"
    done
    for sn in $("$awscli" ec2 describe-subnets --filter "Name=vpc-id,Values=$vpc" --query "Subnets[*].SubnetId" --output text); do
        "$awscli" ec2 delete-subnet --subnet-id "$sn"
    done
    "$awscli" ec2 delete-vpc --vpc-id "$vpc"
done

for hz in $("$awscli" route53 list-hosted-zones | jq -r '.HostedZones[]|select(.Name == "'"$domain"'.").Id'); do
    change_batch=$(mktemp)
    for a_record in registry. proxy.; do
        for rrs_name in $("$awscli" route53 list-resource-record-sets --hosted-zone-id "$hz" | jq -r '.ResourceRecordSets[]|select(.Name|startswith("'"$a_record"'")).Name' || echo ""); do
            rrs=$("$awscli" route53 list-resource-record-sets --hosted-zone-id "$hz" | jq '.ResourceRecordSets[]|select(.Name == "'"$rrs_name"'")') ||:
            if [ -n "$rrs" ]; then
                cat << EOF > "$change_batch"
{
    "Comment": "Teardown cleanup of records",
    "Changes": [{
        "Action": "DELETE",
        "ResourceRecordSet": $rrs
    }]
}
EOF
                "$awscli" route53 change-resource-record-sets --hosted-zone-id "$hz" --change-batch "file://$change_batch"
            fi
        done
    done
    rm -f "$change_batch"
done

for hz in $("$awscli" route53 list-hosted-zones | jq -r '.HostedZones[]|select(.Name == "'"internal.$cluster.$domain"'.").Id'); do
    change_batch=$(mktemp)
    for a_record in registry. proxy. bastion.; do
        for rrs_name in $("$awscli" route53 list-resource-record-sets --hosted-zone-id "$hz" | jq -r '.ResourceRecordSets[]|select(.Name|startswith("'"$a_record"'")).Name' || echo ""); do
            rrs=$("$awscli" route53 list-resource-record-sets --hosted-zone-id "$hz" | jq '.ResourceRecordSets[]|select(.Name == "'"$rrs_name"'")') ||:
            if [ -n "$rrs" ]; then
                cat << EOF > "$change_batch"
{
    "Comment": "Teardown cleanup of records",
    "Changes": [{
        "Action": "DELETE",
        "ResourceRecordSet": $rrs
    }]
}
EOF
                "$awscli" route53 change-resource-record-sets --hosted-zone-id "$hz" --change-batch "file://$change_batch"
            fi
        done
    done
    rm -f "$change_batch"
    "$awscli" route53 delete-hosted-zone --id "$hz"
done

for ak in $("$awscli" iam list-access-keys --user-name "${cluster}.${domain}-registry" --query 'AccessKeyMetadata[*].AccessKeyId' --output text); do
    "$awscli" iam delete-access-key --user-name "${cluster}.${domain}-registry" --access-key-id "$ak"
done
for policy in $("$awscli" iam list-attached-user-policies --user-name "${cluster}.${domain}-registry" --query "AttachedPolicies[*].PolicyArn" --output text); do
    "$awscli" iam detach-user-policy --user-name "${cluster}.${domain}-registry"  --policy-arn "$policy"
    "$awscli" iam delete-policy --policy-arn "$policy"
done
"$awscli" iam delete-user --user-name "${cluster}.${domain}-registry"

for ak in $("$awscli" iam list-access-keys --user-name "${cluster}.${domain}-ocp-installer" --query 'AccessKeyMetadata[*].AccessKeyId' --output text); do
    "$awscli" iam delete-access-key --user-name "${cluster}.${domain}-ocp-installer" --access-key-id "$ak"
done
for policy in $("$awscli" iam list-attached-user-policies --user-name "${cluster}.${domain}-ocp-installer" --query "AttachedPolicies[*].PolicyArn" --output text); do
    "$awscli" iam detach-user-policy --user-name "${cluster}.${domain}-ocp-installer"  --policy-arn "$policy"
    "$awscli" iam delete-policy --policy-arn "$policy"
done
"$awscli" iam delete-user --user-name "${cluster}.${domain}-ocp-installer"
