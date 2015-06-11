#!/bin/sh
# -------------------------------------------------------------------------
# zoneSync v0.1.0
# Copyright (c) 2015 True Negative LLC 
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
# Last Updated: 2015/06/11
# -------------------------------------------------------------------------



SLAVESVR='173.45.225.9';                                # Change this to set your slave server
SLAVEFILEPATH='/var/named/zonesync';			        # Standard bind install on slave server
#SLAVEFILEPATH='/var/named/chroot/var/named/zonesync';	# chrooted bind install on slave server

MASTERIP=`hostname -i`;                                 # Get IP Address
#MASTERIP='0.0.0.0';                                    # Uncomment if you wish to manually set the master IP
NAMEDPATH='/var/named';                                 # Path to named files on local (master)
#NAMEDPATH='/var/named/chroot/var/named';               # Use for chrooted installations of named
NAMEDCONF='/etc/named.conf';                            # bind configuration file
HOMEDIR='/home/zonesync';
ZSCONFDIR="$HOMEDIR/conf";
LOGDIR="$HOMEDIR/log";


## EDIT BELOW AT YOUR OWN RISK ##

SLAVEZONEPATH='/var/named/zonesync/slaves';
SLAVEZSCONF="$SLAVEFILEPATH/zonesync.$MASTERIP.named.conf";
SLAVETMP="$ZSCONFDIR/slaves.named.tmp";
NAMEDMSTR="$ZSCONFDIR/named.master.conf";
ZSCONF="$ZSCONFDIR/zonesync.slaves.conf";
ZSLOG="$LOGDIR/zonesync.log";


## BEGIN ##
VERSION="0.1.0";
umask 033
DATE=`date`;
RSYNC=`which rsync`;

echo "zoneSync v$VERSION (c) 2015 True Negative LLC";
echo "Licensed under GPL";
echo $DATE;
echo -e "\n\nRemoving previous files...";
rm -f $ZSCONFDIR/*;
echo "Done."

echo "# Created by zoneSync"  > $SLAVETMP;

echo "Server: $MASTERIP";
echo "Retrieving local zones...";

grep "^[[:space:]]*zone" $NAMEDCONF|grep -v '^#'|grep -v "/zonesync/"|grep "type master"|perl -pe 's/^\s+//' >> $NAMEDMSTR;

echo "Retrieving includes...";
for include in `grep "^include" $NAMEDCONF|grep -v 'rndc.key'|grep -v "/zonesync/"|cut -d " " -f 2|cut -d "\"" -f 2|uniq`
	do echo "Include: $include";
	if echo $include | grep -qe "^/" ex
		then  grep -P "^[\s]+zone" $include|grep -v '^#'|grep -v "/zonesync/"|grep "type master" >> $NAMEDMSTR;
	else
		grep -P "^[\s]+zone" $NAMEDPATH/$include|grep -v '^#'|grep -v "/zonesync/"|grep "type master" >> $NAMEDMSTR;
	fi
done

if [ -f $SLAVEZSCONF ]
	then
	#do echo "zoneSync :: Including $incl";
	grep "^zone" $SLAVEZSCONF | grep -v '^#' | grep "type slave" >> $ZSCONF;
fi

for domain in `grep "^zone" $NAMEDMSTR | grep 'master' | grep -v 'type slave'| cut -d"\"" -f 2`
	do
		SLAVELINE="zone \"$domain\" { type slave; file \"$SLAVEZONEPATH/$domain.db\"; masters { $MASTERIP; }; }; ";
		echo "${SLAVELINE}" >> $SLAVETMP;
done

if [ -f $ZSCONF ]
	then
	echo -e "\n\n" >> $SLAVETMP;
	cat $ZSCONF >> $SLAVETMP;
fi

echo "Synchronizing to slave server: $SLAVESVR ($SLAVEZSCONF)";
$RSYNC -azve \"ssh -p $RPRT $SLAVETMP $SLAVESVR:$SLAVEZSCONF\"

if [ "$?" -eq "0" ]
then
  echo "Successful synchronization to $SLAVESVR."
else
  echo "Error synchronizing. :("
fi
