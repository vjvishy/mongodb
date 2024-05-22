#!/bin/bash

# Check if all parameters are provided
if [ $# -ne 3 ]; then
  echo "Usage: $0 <PUBLIC_DNS> <DATABASE> <S3_BUCKET_NAME>"
  exit 1
fi

# Set parameters
PUBLIC_DNS=$1
DATABASE=$2
S3_BUCKET_NAME=$3

# MongoDB Public DNS 
HOST=$PUBLIC_DNS

# MongoDB Database that will be backed up
DBNAMES=($DATABASE)

# AWS S3 bucket name
BUCKET=$S3_BUCKET_NAME

# Linux user account
USER=ubuntu

# Current time
TIME=`/bin/date +%d-%m-%Y-%T`

# Backup directory where files will be stored locally
DEST=/home/$USER/mongodb-backup
echo "Backup Directory $DEST"

# Tar file of backup directory
TAR=$DEST/$TIME.tar
echo "TAR File Name $TAR"

# Create backup dir
/bin/mkdir -p $DEST

# Log
echo "Backing up $HOST/$DBNAME to s3://$BUCKET/ on $TIME";

# Dump from mongodb host into backup directory
for DBNAME in "${DBNAMES[@]}"
do
   /usr/bin/mongodump -h $HOST:27017 -u "myUserAdmin" -p "abc123" -d $DBNAME -o $DEST &
done

wait

# Create tar of backup directory
/bin/tar cvf $TAR -C $DEST .

# Upload tar to s3
/usr/local/bin/aws s3 cp $TAR s3://$BUCKET/

# Remove tar file locally
/bin/rm -f $TAR

# Remove backup directory
#/bin/rm -rf $DEST

# All done
echo "Backup available at https://s3.amazonaws.com/$BUCKET/$TIME.tar"