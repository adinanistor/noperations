#!/bin/bash
# Nagios check for files on AWS S3.
# This script will check if the backup archive exists for the previous day.
# Adina Nistor - 2017

#set -x

file_date=$(date +%F --date "1 days ago")

# Insert the path where the backup is being saved.
aws s3 ls s3://path/to/backup | grep $file_date | cut -d" " -f5

if [ $? -eq 0 ]
then
    echo "OK- Backup for yesterday exists."
else
    echo "CRITICAL- Backup for yesterday NOT FOUND on S3."
fi
