import boto3
import logging
from datetime import *
import re

#setup simple logging for INFO
logger = logging.getLogger()
logger.setLevel(logging.INFO)

#define the connection and the region (eg. eu-central-1)
ec2 = boto3.resource('ec2', region_name=" ")

#aws account number
AWSAccount = '123123123123'

#set the date to today for the snapshot
today = datetime.now().date()

#set the snapshot removal offset
cleanDate = today-timedelta(days=14)

def lambda_handler(event, context):
    
    #snapshot all instances
    base = ec2.instances.all()
    
    #loop through by running instances
    for instance in base:
        for t in instance.tags:
            #pull the name tag
            if t['Key'] == 'Name':
                instanceName =  t['Value']
        
        #snapshop the instances
        for vol in instance.volumes.all():
            description = str(today) + "-" + instanceName + "-" + vol.id + "-automated"
            #snapshot that server
            snapshot = ec2.create_snapshot(VolumeId=vol.id, Description=description)
            print snapshot
    
    #regular expression for YYYY-MM-DD
    datePattern = re.compile('^(?:(?:(?:(?:(?:[13579][26]|[2468][048])00)|(?:[0-9]{2}(?:(?:[13579][26])|(?:[2468][048]|0[48]))))-(?:(?:(?:09|04|06|11)-(?:0[1-9]|1[0-9]|2[0-9]|30))|(?:(?:01|03|05|07|08|10|12)-(?:0[1-9]|1[0-9]|2[0-9]|3[01]))|(?:02-(?:0[1-9]|1[0-9]|2[0-9]))))|(?:[0-9]{4}-(?:(?:(?:09|04|06|11)-(?:0[1-9]|1[0-9]|2[0-9]|30))|(?:(?:01|03|05|07|08|10|12)-(?:0[1-9]|1[0-9]|2[0-9]|3[01]))|(?:02-(?:[01][0-9]|2[0-8])))))')
    
    print "Cleaning out old entries starting on " + str(cleanDate)
    
    #clean up old snapshots
    for snap in ec2.snapshots.filter(Filters=[{'Name': 'owner-id', 'Values': [AWSAccount]}]):
        results = datePattern.match(snap.description)
        
        #veryify results have a value
        if results is not None:
            
            snapDate = datetime.strptime(results.group(0),'%Y-%m-%d').date()
            
            #check the age of the snapshot, delete the old ones
            if cleanDate > snapDate:
                print "Deleteing: " + snap.id + " - From: " + str(snapDate)
                snapshot = ec2.Snapshot(snap.id).delete()
                print snapshot
