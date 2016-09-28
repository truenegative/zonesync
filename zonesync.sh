#!/bin/bash
# -------------------------------------------------------------------------
# zoneSync v0.2.0
# Copyright (c) 2016 True Negative LLC 
#
# This program is free software: you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation, either version 3 of the License, or (at your option) any later 
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# For a copy of the GPL V3, see http://www.gnu.org/licenses/.
# 
# Last Updated: 2016/09/28
# -------------------------------------------------------------------------


source ./config/zs.conf


## EDIT BELOW AT YOUR OWN RISK ##
#################################

SLAVEZONEPATH='/var/named/zonesync/slaves';
SLAVEZSCONF="$SLAVEFILEPATH/zonesync.$MASTERIP.named.conf";
SLAVETMP="$ZSCONFDIR/slaves.named.tmp";
NAMEDMSTR="$ZSCONFDIR/named.master.conf";
ZSCONF="$ZSCONFDIR/zonesync.slaves.conf";
ZSLOG="$LOGDIR/zonesync.log";


## BEGIN ##
VERSION="0.2.0";
umask 033
DATE=`date`;
YEAR=`date +"%Y"`
RSYNC=`which rsync`;
RSYNCARGS="-a -vv -z"
RRSH="ssh -q -p $RPRT";


## CREATE CONF/LOG FOLDERS IF NEEDED ##
mkdir -p $ZSCONFDIR;
mkdir -p $LOGDIR;

echo -e "\n\nzoneSync v$VERSION (c) $YEAR True Negative LLC";
echo "Licensed under GPL v3";
echo $DATE;
echo -e "\n\nRemoving previous files...";
rm -f $ZSCONFDIR/*;
echo "Done."

echo "# Created by zoneSync v$VERSION (c) $YEAR True Negative LLC"  > $SLAVETMP;

echo "Server: $MASTERIP";
echo "Retrieving local zones...";

grep "^[[:space:]]*zone" $NAMEDCONF|grep -v '^#'|grep -v "/zonesync/"|grep "type master"|perl -pe 's/^\s+//' >> $NAMEDMSTR;
echo "Done."

echo "Retrieving local includes...";
for include in `grep "^include" $NAMEDCONF|grep -v '.key'|grep -v "/zonesync/"|cut -d " " -f 2|cut -d "\"" -f 2|uniq`
	do 
		echo "Include: $include";
		grep -P "^[\s]+zone" $include|grep -v '^#'|grep -v "/zonesync/"|grep "type master" >> $NAMEDMSTR;
done
echo "Done."

echo "Modifying local zones...";
for domain in `grep "^zone" $NAMEDMSTR | grep 'master' | grep -v 'type slave'| cut -d"\"" -f 2`
	do
		SLAVELINE="zone \"$domain\" { type slave; file \"$SLAVEZONEPATH/$domain.db\"; masters { $MASTERIP; }; }; ";
		echo "${SLAVELINE}" >> $SLAVETMP;
done
echo "Done."

echo "Retrieving slave zones...";
for include in `grep "^include" $NAMEDCONF|grep -v '.key'|grep  "/zonesync/"|cut -d " " -f 2|cut -d "\"" -f 2|uniq`
	do 
		echo "Include: $include";
		grep "^[[:space:]]*zone" $include | perl -pe 's/^\s+//' >> $ZSCONF;
done

if [ -f $ZSCONF ]
	then
	echo -e "\n\n" >> $SLAVETMP;
	cat $ZSCONF >> $SLAVETMP;
fi
echo -e "Done.\n\n"

echo "Synchronizing to slave server: $SLAVESVR ($SLAVEZSCONF)";
export RSYNC_RSH=$RRSH;
$RSYNC $RSYNCARGS $SLAVETMP $SLAVESVR:$SLAVEZSCONF

echo -e "\n\n"

if [ "$?" -eq "0" ]
then
  echo "Successful synchronization to $SLAVESVR."
else
  echo "Error synchronizing. :("
fi

echo -e "\n\nReloading slave configuration...";
ssh -q -p $RPRT $SLAVESVR "$SLAVERNDC";

if [ "$?" -eq "0" ]
then
  echo "Done."
else
  echo "Error Reloading Slave Configuration on $SLAVESVR"
fi

