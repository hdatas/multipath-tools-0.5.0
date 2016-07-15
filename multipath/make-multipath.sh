#!/bin/bash

#This script will scan the system for attached HCD Volumes
# and output a list of multipath alias statements for the linux
# /etc/multipath.conf.  This will allow for the volume to be
# referenced by the volume name in place of the normal mpathX
#
# To use the script, just run it.  If HCD volumes are present
# it will output the confiugration data to standard out
# Just copy and paste that output in to /etc/multipath.conf
# Take care when adding these lines to make sure another alias
# is not present or if there are other multipath statements

# Start by checking to see if we have any HCD volumes connected
#modprobe dm-multipath
#multipathd

ls -l /dev/disk/by-path | grep hcd >/dev/null

if [ $? -eq 0 ]
then
sleep 1
#Build list of HCD devices
DEV_LIST=$(ls -l /dev/disk/by-path | grep hcd | awk '{print $NF'} | sed 's/..\/..\///')
echo "defaults {
    user_friendly_names     yes
    path_grouping_policy    failover
    polling_interval        3
    path_selector           \"round-robin 0\"
#    failback                immediate
    features                \"1 queue_if_no_path\"
#    no_path_retry           1
}" > /etc/multipath.conf

# Output the first line of the config
echo "multipaths {" >> /etc/multipath.conf
echo $DEV_LIST
# For each device found we determine the name and the mpathid
for i in $DEV_LIST
  do
  SUBSTRING=$(ls -l /dev/disk/by-id | grep scsi | grep $i  | awk -F- '{print $2}')
  if [ "$SUBSTRING" == "" ]
  then
    continue
  else
    echo $SUBSTRING
  fi
  # This uses pattern matching to find the name of the volume
#OFFSET=$(echo $SUBSTRING | awk --re-interval 'match($0, /\-[v][a-z0-9]{16}/) { print RSTART-1 }')
#OFFSET=$(echo $SUBSTRING | awk 'match($0, /\-[v][a-z0-9]{16}/) { print RSTART-1 }')
#  echo $OFFSET
#  exit 0
  NIMBLEVOL=${SUBSTRING::$OFFSET}
  NIMBLEVOL=${SUBSTRING}

  # Here we collect the MPATHID
  MPATHID=$(multipath -ll /dev/$i | grep HCD | awk '{print $2}' | sed -e 's\(\\g' | sed -e 's\)\\g')

  # Enable for debug
#echo "Volume name for $device is $nimblevol with multipath ID is $mpathid"

  # Putting it all together with proper formatting using printf
#  MULTIPATH=$(printf "multipath {\n \t\twwid \t\t%s \n \t\talias\t\t %s\n \t}" $MPATHID $NIMBLEVOL)
  MULTIPATH=$(printf "multipath {\n \t\twwid \t\t%s \n \t\talias\t\t %s\n \t}" ${SUBSTRING} $NIMBLEVOL)
  MATCH='multipaths {'

  echo "$MULTIPATH" >> /etc/multipath.conf

  done

  # End the configuration section
  echo "}" >> /etc/multipath.conf
  multipath -r
else

  # If no HCD devices found, exit with message
  echo "No HCD Devices Found, have you met leeloo?"
  exit 1
fi
#multipath -r
exit 0
