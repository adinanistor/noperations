#!/bin/bash
# Start/Stop machines via Rundeck
# Adina Nistor - 2017

set -o errexit

# Select from drop-down list Start or Stop
ACTION=$1
# Select from drop-down list the instance that needs to be started/stopped.
MACHINE=$2

echo "Running $0 $*"
echo "${MACHINE} will ${ACTION} ..."
machine_instance_id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${MACHINE}" --query 'Reservations[*].Instances[*].InstanceId[]' --output text)
current_machine_status=$(aws ec2 describe-instance-status --instance-ids ${machine_instance_id} --query 'InstanceStatuses[*].InstanceState[].Name[]' --output text)

if [ "${current_machine_status}" == "running" ]
then
    if [ "${ACTION}" == "start" ]
    then
        echo "${MACHINE} is already running. Leaving machine as it is."
        break
    else


aws ec2 ${ACTION}-instances --instance-ids ${machine_instance_id}
echo "${MACHINE} is being ${ACTION}ed."
