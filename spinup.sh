#!/usr/bin/env bash

ACCT="--profile aws-wmcso-globalprotect-prod:aws-wmcso-globalprotect-prod-admin --region $1"
EC2="aws ec2"

# echo ${ACCT}

_EXISTS(){
    if [[ $(echo "$1" | jq '.SecurityGroups | length') -eq 1 ]]; then
      echo "0"
    else
      echo "1"
    fi
}

VPC=`${EC2} describe-vpcs ${ACCT} --filters "Name=isDefault,Values=true" | jq '.Vpcs[]'`
VPCID=$(echo ${VPC} | jq -r '.VpcId')



SUBNET=`${EC2} describe-subnets ${ACCT} --filters "Name=availability-zone,Values=us-east-1a"`

SGMGMT=`${EC2} describe-security-groups ${ACCT} --filters "Name=group-name,Values=panos-mgmt"`
SGGP=`${EC2} describe-security-groups ${ACCT} --filters "Name=group-name,Values=globalprotect"`
for v in SGMGMT SGGP; do
    if [[ $(_EXISTS "${$(echo ${v})}") -eq 0 ]]; then
        echo "Missing ${v} profile; terminating..."
        exit 2
    fi
done
