#!/bin/bash
# Backup database
# Adina Nistor - 2015

set -o errexit

echo "Running $0 $*"

# Suffix can be ongoing or ondemand.
SUFFIX=$1

# Fill in host, database name, username and password.
DB_HOST=" "
DB_NAME=" "
DB_USERNAME=" "
DB_PASSWORD=" "

CURRENT_DATE=$(date +%Y-%m-%d)

if [ -z $SUFFIX ]
then
backup_folder_name=${DB_NAME}-${CURRENT_DATE}-backup
else
backup_folder_name=${DB_NAME}-${CURRENT_DATE}-backup-${SUFFIX}
fi

temp_backup_folder=/tmp/backup/${backup_folder_name}
mkdir -p ${temp_backup_folder}

echo "Backing up DB ... "
backup_sql=${temp_backup_folder}/${backup_folder_name}.sql
export PGPASSWORD="${DB_PASSWORD}"
pg_dump -h ${DB_HOST} -U ${DB_USERNAME} ${DB_NAME} > ${backup_sql}
echo "Done backing up. Uploading backup to S3 ..."

tar cfjv ${temo_backup_folder} --checkpoint=.1000 -C ${backup_sql} .

# Update path to backup.
s3backup=s3://path/to/backup/${backup_sql}

aws s3 cp ${backup_sql} ${s3backup}
echo "Upload backup done."
rm -r /tmp/backup/*
echo "Finished."