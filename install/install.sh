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

VERSION="0.2.0";
INSTALL_LOG="/tmp/zs_install.log";
ZS_CONF="./config/zs.conf";

# FUNCTIONS

function menu() {
    clear;
    echo    " |============================================|";
    echo    " | :: zoneSync v$VERSION Installer               |"
    echo    " |--------------------------------------------|";
    echo    " | Choose Install Type                        |";
    echo    " |     [1] Master                             |";
    echo    " |     [2] Slave                              |";
    echo    " |                                            |";
    echo    " |     ** Slave Should be Installed First **  |";
    echo    " |============================================|";
    echo    "";
    printf    " Choose an option: ";
    read option;

    until [ "${option}" = "1" ] || [ "${option}" = "2" ]; do
        printf " Please enter a valid option: ";
        read option;
    done; 

    if [ "${option}" = "1" ]; then
        echo "";
        echo "Have you installed configured the Slave? (Y/N): ";
        read slaveopt;

        until [ "${slaveopt}" == "Y" ] || [ "${slaveopt}" == "y" ] || [ "${slaveopt}" == "N" ] || [ "${slaveopt}" == "n" ]; do
            print " Please enter (Y/N/y/n): ";
            read slaveopt;
        done;

        if [ "${slaveopt}" == "N" ] || [ "${slaveopt}" == "n" ]; then
            echo "You need to configure slave zoneSync first! Please run this script on the slave.";
            exit 0;
        fi;

        installMaster;

    elif [ "${option}" = "2" ]; then
        installSlave;
    fi;
};

# Install Master Function
function installMaster() {
    clear;
    echo "Installing zoneSync Master...";
    echo "";

    # Add User zonesync
    echo "Adding user zonesync...";
    #useradd zonesync;
    echo "OK";
    echo "Please enter a password for user zonesync";
    #passwd zonesync;
    echo "OK";
    echo "";
    echo "Modifying zonesync user group..."
    #usermod -G named zonesync;
    echo "OK";
    echo "";
    
    # Add SSH Keys
    echo "Generating SSH Keys...";
    #su - zonesync -C "ssh-keygen -t rsa -b 4096 -N ''";
    echo "OK";
    echo "";

    # Enter Slave Information
    printf " Enter Slave IP Address: ";
    read slaveip;

    valid_ip ${slaveip};
    until [[ $? -eq 0 ]]; do
        printf " Please enter a valid IP Address: ";
        read slaveip;
        valid_ip ${slaveip};
    done;

    echo "";
    echo "Using Slave IP Addres: ${slaveip}";
    echo "";

    printf " Enter Slave SSH Port: ";
    read slavesshport;

    port_is_ok ${slavesshport};
    until [[ $? -eq 0 ]]; do
        printf " Please enter a valid port: ";
        read slavesshport;
        port_is_ok ${slavesshport};
    done;

    echo "";
    echo "Slave SSH Port: ${slavesshport}";
    echo "";

    # Copy Public Key Over to Slave
    echo "Coping Public Key Over to Slave Server...";
    #mkdir -p .ssh && cat .ssh/id_rsa.pub | ssh -p ${slavesshport} zonesync@${slaveip} 'cat >> .ssh/authorized_keys && chmod 700 .ssh && chmod 600 .ssh/authorized_keys'
    echo "OK";
    echo "";

    # Check SSH Status
    echo "Checking SSH Status...";
    status=$(ssh -q -o BatchMode=yes -o ConnectTimeout=5 -p ${slavesshport} zonesync@${slaveip} echo ok 2>&1);
    if [[ $status == ok ]] ; then
        echo "AUTH Successful!";
    elif [[ $status == "Permission denied"* ]] ; then
        echo "AUTH Not Successful. Please check Slave IP and Port and Try Again";
        exit 1;
    else
        echo "Error checking SSH Status...";
        exit 1;
    fi

    echo "";

    clear;

    # Check for chroot'd master install 
    echo "Is your MASTER bind (named) install chrooted? (Y/N): ";
    read chrooted;

    until [ "${chrooted}" == "Y" ] || [ "${chrooted}" == "y" ] || [ "${chrooted}" == "N" ] || [ "${chrooted}" == "n" ]; do
        print " Please enter (Y/N/y/n): ";
        read chrooted;
    done;

    if [ "${chrooted}" == "N" ] || [ "${chrooted}" == "n" ]; then
        namedpath = "/var/named";
    else
        namedpath = "/var/named/chroot/var/named";
    fi;

    # Check for chroot'd slave install 
    echo "Is your SLAVE bind (named) install chrooted? (Y/N): ";
    read chrooted;

    until [ "${chrooted}" == "Y" ] || [ "${chrooted}" == "y" ] || [ "${chrooted}" == "N" ] || [ "${chrooted}" == "n" ]; do
        print " Please enter (Y/N/y/n): ";
        read chrooted;
    done;

    if [ "${chrooted}" == "N" ] || [ "${chrooted}" == "n" ]; then
        slavefilepath = "/var/named/zonesync";
    else
        slavefilepath = "/var/named/chroot/var/named/zonesync";
    fi;


    
    # Set configuration
    echo "Writing configuration...";

    # Slave Server IP
    perl -pi -e "s/SLAVESVR=\'.+\'/SLAVESVR=\'${slaveip}\'/g" $ZS_CONF;

    # Slave Server Port
    perl -pi -e "s/RPRT=\'.+\'/RPRT=\'${slavesshport}\'/g" $ZS_CONF;

    # Master Named path
    perl -pi -e "s/NAMEDPATH=\'.+\'/NAMEDPATH=\'${namedpath}\'/g" $ZS_CONF;

    # Slave File path
    perl -pi -e "s/SLAVEFILEPATH=\'.+\'/SLAVEFILEPATH=\'${slavefilepath}\'/g" $ZS_CONF;


};


# Install Slave Function
function installSlave() {
    clear;
    echo "Installing zoneSync Slave...";
    echo "";

    # Add User zonesync
    echo "Adding user zonesync...";
    #useradd zonesync;
    echo "OK";
    echo "Please enter a password for user zonesync";
    #passwd zonesync;
    echo "OK";
    echo "";
    echo "Modifying zonesync user group..."
    #usermod -G named zonesync;
    echo "OK";
    echo "";
    
    # Add SSH Keys
    echo "Generating SSH Keys...";
    #su - zonesync -C "ssh-keygen -t rsa -b 4096 -N ''";
    echo "OK";
    echo "";

    clear;

    # Enter Master Information
    printf " Enter Master IP Address: ";
    read masterip;

    valid_ip ${masterip};
    until [[ $? -eq 0 ]]; do
        printf " Please enter a valid IP Address: ";
        read masterip;
        valid_ip ${masterip};
    done;

    echo "";
    echo "Using Master IP Addres: ${masterip}";
    echo "";

    # Check for chroot'd install 
    echo "Is your bind (named) install chrooted? (Y/N): ";
    read chrooted;

    until [ "${chrooted}" == "Y" ] || [ "${chrooted}" == "y" ] || [ "${chrooted}" == "N" ] || [ "${chrooted}" == "n" ]; do
        print " Please enter (Y/N/y/n): ";
        read chrooted;
    done;

    if [ "${chrooted}" == "N" ] || [ "${chrooted}" == "n" ]; then
        echo "Standard Bind Install. OK";
        echo "";
        
        echo "Creating zoneSync folders...";
        #mkdir -p /var/named/zonesync && mkdir -p /var/named/zonesync/slaves
        #touch /var/named/zonesync/zonesync.${masterip}.named.conf;
        echo "OK";
        echo "";
        
        echo "Setting Permissions...";
        #chown -R zonesync:named /var/named/zonesync && chmod -R 770 /var/named/zonesync
        echo "OK";
        echo "";

        echo "Adding zoneSync config to named.conf...";
        #cat "include \"zonesync/zonesync.${masterip}.named.conf\";" >> /etc/named.conf
        echo "OK";
        echo "";
    
    else   
        echo "Chroted Bind Install. OK";
        echo "";
        
        echo "Creating zoneSync folders...";
        #mkdir -p /var/named/chroot/var/named/zonesync && mkdir -p /var/named/chroot/var/named/zonesync/slaves
        #touch /var/named/chroot/var/named/zonesync/zonesync.${masterip}.named.conf;
        echo "OK";
        echo "";
        
        echo "Setting Permissions...";
        #chown -R zonesync:named /var/named/chroot/var/named/zonesync && chmod -R 770 /var/named/chroot/var/named/zonesync
        echo "OK";
        echo "";

        echo "Adding zoneSync config to named.conf...";
        #cat "include \"zonesync/zonesync.${masterip}.named.conf\";" >> /etc/named.conf
        echo "OK";
        echo "";
    fi;

    echo "Slave install complete. Please install master on: ${masterip} ";
    echo "";
    echo "Enjoy!";
};


# PreCheck Function 
function preCheck() {
    echo "Checking for root..."
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root." 1>&2
        exit 1;
    fi;
    echo "";

    echo "Checking for prerequisites...";
    echo "Perl...";
    if hash perl 2>/dev/null; then
        echo "OK";
    else
        echo "Perl is required. Please install.";
        exit 1;
    fi;
    
    echo "rsync...";
    if hash rsync 2>/dev/null; then
        echo "OK";
    else
        echo "rsync is required. Please install.";
        exit 1;
    fi;
    
    echo "Bind (named)...";
    if hash named 2>/dev/null; then
        echo "OK";
    else
        echo "Bind (named) is required. Please install.";
        exit 1;
    fi;

    echo "Testing for cron...";
    if hash crontab 2>/dev/null; then
        echo "OK";
        CRONTAB=1;
    else
        echo "Cron not installed. Adding to crontab disabled.";
        CRONTAB=0;
    fi;
};

# Valid IP 
function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# Valid Port Functions

function to_int {
    local -i num="10#${1}"
    echo "${num}"
}
 
function port_is_ok {
    local port="$1"
    local -i port_num=$(to_int "${port}" 2>/dev/null)
    local stat=0;
 
    if (( $port_num < 1 || $port_num > 65535 )) ; then
        stat=1;
    else
        stat=0;
    fi
 
    return $stat;
}

preCheck;
menu;




