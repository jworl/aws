#!/usr/bin/env bash

ACCT="--profile aws-wmcso-globalprotect-prod:aws-wmcso-globalprotect-prod-admin --region $1"
ZONE=$2
AVZN=$1$2
EC2="aws ec2"

# echo ${ACCT}

_EXISTS(){
    if [[ $(echo "$1" | jq ".$2 | length") -eq 1 ]]; then
      echo "0"
    else
      echo "1"
    fi
}

VPC=`${EC2} describe-vpcs ${ACCT} --filters "Name=isDefault,Values=true" | jq '.Vpcs[]'`
VPCID=$(echo ${VPC} | jq -r '.VpcId')


SUBNET=`${EC2} describe-subnets ${ACCT} --filters "Name=availability-zone,Values=${AVZN}"`
SNSTATE=$(echo ${SUBNET} | jq -r ".Subnets[].State")
if [[ ${SNSTATE} != "available" ]]; then 
    echo "${AVZN} is ${SNSTATE}"; exit 2
else
    SNID=$(echo ${SUBNET} | jq -r .Subnets[].SubnetId)
    echo "${AVZN} subnet-id is ${SNID}"
fi

SGMGMT=`${EC2} describe-security-groups ${ACCT} --filters "Name=group-name,Values=panos-mgmt"`
if [[ $(_EXISTS "${SGMGMT}" "SecurityGroups") -eq 1 ]]; then
    echo "missing SG for MGMT"; exit 2
else
    SGMGMTID=$(echo ${SGMGMT} | jq -r .SecurityGroups[].GroupId)
    echo "GroupId for MGMT is ${SGMGMTID}"
fi

SGGP=`${EC2} describe-security-groups ${ACCT} --filters "Name=group-name,Values=globalprotect"`
if [[ $(_EXISTS "${SGGP}" "SecurityGroups") -eq 1 ]]; then echo "missing SG for GlobalProtect"; exit 2; fi

NIMGMT=`${EC2} describe-network-interfaces ${ACCT} --filters "Name=availability-zone,Values=${AVZN}" "Name=group-id,Values=${SGMGMTID}"`
echo ${NIMGMT} | jq .