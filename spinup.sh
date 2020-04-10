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
    echo "${AVZN} subnet-id: ${SNID}"
fi

SGMGMT=`${EC2} describe-security-groups ${ACCT} --filters "Name=group-name,Values=panos-mgmt"`
if [[ $(_EXISTS "${SGMGMT}" "SecurityGroups") -eq 1 ]]; then
    echo "missing SG for MGMT"; exit 2
else
    SGMGMTID=$(echo ${SGMGMT} | jq -r .SecurityGroups[].GroupId)
    echo "GroupId for MGMT: ${SGMGMTID}"
fi

SGGP=`${EC2} describe-security-groups ${ACCT} --filters "Name=group-name,Values=globalprotect"`
if [[ $(_EXISTS "${SGGP}" "SecurityGroups") -eq 1 ]]; then
    echo "missing SG for GlobalProtect"; exit 2
else
    SGGPID=$(echo ${SGGP} | jq -r .SecurityGroups[].GroupId)
    echo "GroupId for GlobalProtect: ${SGGPID}"
fi

NIMGMT=`${EC2} describe-network-interfaces ${ACCT} --filters "Name=availability-zone,Values=${AVZN}" "Name=group-id,Values=${SGMGMTID}"`
if [[ $(_EXISTS "${NIMGMT}" "NetworkInterfaces") -eq 1 ]]; then
    echo "missing NetworkInterface for MGMT"; exit 2
else
    NIMGMTID=$(echo ${NIMGMT} | jq -r ".NetworkInterfaces[].NetworkInterfaceId")
    echo "NetworkInterfaceID for MGMT: ${NIMGMTID}"
fi

NIGP=`${EC2} describe-network-interfaces ${ACCT} --filters "Name=availability-zone,Values=${AVZN}" "Name=group-id,Values=${SGGPID}"`
if [[ $(_EXISTS "${NIGP}" "NetworkInterfaces") -eq 1 ]]; then
    echo "missing NetworkInterface for MGMT"; exit 2
else
    NIGPID=$(echo ${NIGP} | jq -r ".NetworkInterfaces[].NetworkInterfaceId")
    echo "NetworkInterfaceID for GlobalProtect: ${NIGPID}"
fi
