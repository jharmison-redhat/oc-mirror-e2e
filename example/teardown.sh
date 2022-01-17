#!/bin/bash

read -sp "WARNING! This script does not save your Terraform state. Are you sure you want to destroy the terraformed infrastructure, without recovering state? Press Enter to continue, or Ctrl+C to cancel." throwaway
echo

set -x

cluster=disco
domain=redhat4govaws.io

domain_hyphenated=$(echo "$domain" | tr '.' '-')
domain_underscored=$(echo "$domain" | tr '.' '_')


aws s3 rb "s3://${cluster}-${domain_hyphenated}-registry"

for instance in $(aws ec2 describe-instances --filters Name=tag:Project,Values=disconnected-openshift-testbed Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].InstanceId" --output text); do
    for eip in $(aws ec2 describe-addresses --filter Name=instance-id,Values="$instance" --query "Addresses[*].AllocationId" --output text); do
        assoc=$(aws ec2 describe-addresses --filter Name=allocation-id,Values="$eip" --query "Addresses[*].AssociationId" --output text)
        aws ec2 disassociate-address --association-id "$assoc"
        aws ec2 release-address --allocation-id "$eip"
    done
    aws ec2 terminate-instances --instance-ids "$instance"
done

aws ec2 delete-key-pair --key-name "${cluster}_${domain_underscored}"

for vpc in $(aws ec2 describe-vpcs --filter Name=tag:Project,Values=disconnected-openshift-testbed --query "Vpcs[*].VpcId" --output text); do
    for sg in $(aws ec2 describe-security-groups --filter "Name=vpc-id,Values=$vpc" "Name=group-name,Values=registry.${cluster}.${domain}" --query "SecurityGroups[*].GroupId" --output text); do
        aws ec2 delete-security-group --group-id "$sg"
    done
    for igw in $(aws ec2 describe-internet-gateways --filter "Name=attachment.vpc-id,Values=$vpc" --query "InternetGateways[*].InternetGatewayId" --output text); do
        aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc"
        aws ec2 delete-internet-gateway --internet-gateway-id "$igw"
    done
    for rt in $(aws ec2 describe-route-tables --filter "Name=vpc-id,Values=$vpc" Name=association.main,Values=false --query "RouteTables[*].RouteTableId" --output text); do
        for assoc in $(aws ec2 describe-route-tables --route-table-ids "$rt" --query "RouteTables[*].Associations[*].RouteTableAssociationId" --output text); do
            aws ec2 disassociate-route-table --association-id "$assoc"
        done
        aws ec2 delete-route-table --route-table-id "$rt"
    done
    for sn in $(aws ec2 describe-subnets --filter "Name=vpc-id,Values=$vpc" --query "Subnets[*].SubnetId" --output text); do
        aws ec2 delete-subnet --subnet-id "$sn"
    done
    aws ec2 delete-vpc --vpc-id "$vpc"
done

for hz in $(aws route53 list-hosted-zones | jq -r '.HostedZones[]|select(.Name == "'"$domain"'.").Id'); do
    change_batch=$(mktemp)
    for a_record in registry. proxy.; do
        for rrs_name in $(aws route53 list-resource-record-sets --hosted-zone-id "$hz" | jq -r '.ResourceRecordSets[]|select(.Name|startswith("'"$a_record"'")).Name'); do
            rrs=$(aws route53 list-resource-record-sets --hosted-zone-id "$hz" | jq '.ResourceRecordSets[]|select(.Name == "'"$rrs_name"'")')
            cat << EOF > "$change_batch"
{
    "Comment": "Teardown cleanup of records",
    "Changes": [{
        "Action": "DELETE",
        "ResourceRecordSet": $rrs
    }]
}
EOF
            aws route53 change-resource-record-sets --hosted-zone-id "$hz" --change-batch "file://$change_batch"
        done
    done
    rm -f "$change_batch"
done

for ak in $(aws iam list-access-keys --user-name "${cluster}.${domain}-registry" --query 'AccessKeyMetadata[*].AccessKeyId' --output text); do
    aws iam delete-access-key --user-name "${cluster}.${domain}-registry" --access-key-id "$ak"
done
for policy in $(aws iam list-attached-user-policies --user-name "${cluster}.${domain}-registry" --query "AttachedPolicies[*].PolicyArn" --output text); do
    aws iam detach-user-policy --user-name "${cluster}.${domain}-registry"  --policy-arn "$policy"
    aws iam delete-policy --policy-arn "$policy"
done
aws iam delete-user --user-name "${cluster}.${domain}-registry"
