#!/bin/bash
# AWS Instances daily snapshots, with 2 week retention.
# As cron, this job is intended to be ran daily.
# Adina Nistor - 2017

echo "Running $0"

INSTANCE_LIST=""

RETENTION_DAYS="14"
RETENTION_DATE_IN_SECONDS=$(date +%s --date "${RETENTION_DAYS} days ago")

# Instances can be indicated within the list or filtered based on a specific tag.
function take_snapshots()
{
	echo "Taking snapshots for Prod machines.."
	for instance in ${INSTANCE_LIST}
	do
		instance_id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${instance}" --query 'Reservations[*].Instances[*].InstanceId[]' --output text)
		for volume in $(aws ec2 describe-volumes --filters "Name=attachment.instance-id,Values=${instance_id}" --query 'Volumes[*].VolumeId' --output text)
		do
			aws ec2 create-snapshot --volume-id ${volume} --description "Snapshot created by SnapCron"
			for snapshot in $(aws ec2 describe-snapshots --filters "Name=volume-id,Values=${volume}" --query Snapshots[*].[SnapshotId] --output text)
			do
				snapshot_date=$(aws ec2 describe-snapshots --snapshot-ids ${snapshot} --query 'Snapshots[*].StartTime' --output=text | awk -F "T" '{printf "%s\n", $1}')
				if [ "${snapshot_date}" == "$(date "+%Y-%m-%d")" ]
				then
					snapshot_id_recent=${snapshot}
					aws ec2 create-tags --resources ${snapshot_id_recent} --tags Key=Name,Value=${instance}-${volume}-${snapshot_date}-snapshot
				fi
			done
			echo "Created snapshot.Next."
		done
	done
}

# Purge affects only the screenshots taken through this script (filters out only ones with "Snapshot created by SnapCron" in description)
function purge_snapshots()
{
	echo "Removing snapshots older than ${RETENTION_DAYS} days.."
	for snap in $(aws ec2 describe-snapshots --filters "Name=description,Values='Snapshot created by SnapCron'" --query Snapshots[*].[SnapshotId] --output text)
	do
		snap_start_time=$(aws ec2 describe-snapshots --snapshot-ids ${snap} --query 'Snapshots[*].StartTime' --output=text | awk -F "T" '{printf "%s\n", $1}')
		snap_date_in_seconds=$(date "--date=${snap_start_time}" +%s)
		if [ "${snap_date_in_seconds}" -le "${RETENTION_DATE_IN_SECONDS}" ]
		then
			aws ec2 delete-snapshot --snapshot-id=${snap}
			echo "Deleted snapshot.Next."
		else
			echo "Nothing to delete yet.Next"
		fi
	done
}

### running ###
take_snapshots
purge_snapshots

echo "Hazzar! All done."
