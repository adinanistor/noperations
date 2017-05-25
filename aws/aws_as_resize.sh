#!/bin/bash
# Resize AWS AutoSCaling Groups
# Adina Nistor - 2017

echo "Resize autoscaling groups to the desired MIN and MAX values with MIN as the desired value."

NO_RE='^[0-9]+$'
# insert the names of AS Groups.
AS_GROUPS=" "

MIN=$1
MAX=$2

if ! [[ $MIN =~ $NO_RE ]] ; then
    echo "MIN should be a number and should be present as first parameter."
    exit 1
fi

if ! [[ $MAX =~ $NO_RE ]] ; then
    echo "MAX should be a number and should be the second parameter."
    exit 1
fi

for asgroup in $AS_GROUPS; do
    echo "Resizing auto-scaling group '$asgroup' to min: $MIN, max: $MAX instances ..."
    /usr/bin/aws autoscaling update-auto-scaling-group --auto-scaling-group-name $asgroup --min-size $MIN --desired-capacity $MIN --max-size $MAX
    echo "done."
done
echo "All resizing done."
