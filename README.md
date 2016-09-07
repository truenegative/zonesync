[![GitHub release](https://img.shields.io/github/release/truenegative/zonesync.svg?maxAge=2592000?style=flat-square)](https://github.com/truenegative/zonesync/releases) 
[![license](https://img.shields.io/github/license/truenegative/zonesync.svg?maxAge=2592000)](https://www.gnu.org/licenses/gpl-3.0.en.html)
[![GitHub closed issues](https://img.shields.io/github/issues-closed/truenegative/zonesync.svg?maxAge=2592000?style=flat-square)](https://img.shields.io/github/license/truenegative/zonesync.svg?maxAge=2592000)

# zonesync
zoneSync is a bash script for synchronizing DNS records between masters and slaves. Originally a fork of nobaloney's master-slave script from the DirectAdmin forums, it has been changed and massaged into what it is now.

## Why?
Many companies that use DirectAdmin or other hosting control panels, just use the installed DNS system that the control panel system provides. zoneSync allows even the smallest of hosting servers to use the "hidden master" style of serving up DNS records. Most importantly, using zoneSync allows you to automate the synchronization to your main nameservers whenever you or your customers add a domain to the control panel. 

It's very easy to replicate the DNS zones to 1, 2, 3 or 4 nameservers that can be spread across the globe. Since bind can be configured to be very secure you can limit the services on both the shared hosting server as well as the nameservers.

## Usage / Installation

### Requirements
  * rsync / ssh
  * perl
  * bind (named)
  * cron

### Pre-Install
  1. Ensure all requirements are installed on both master and slave systems.

  2. On Master & Slave:
    * Create user zonesync: `useradd zonesync && passwd zonesync`
    * Modify user zonesync: `usermod -G named zonesync`
    * Change to user zonesync: `su - zonesync`
    * Generate Public/Private Keys: `ssh-keygen -t rsa -b 4096` (no passphrase)

  3. On Master (As user zonesync)
    * Copy Public key over to slave: `mkdir -p .ssh && cat .ssh/id_rsa.pub | ssh -p 22 zonesync@slave.ip.address 'cat >> .ssh/authorized_keys && chmod 700 .ssh && chmod 600 .ssh/authorized_keys'` (You will have to enter the password you set for zonesync above)
    * Test connection w/o pasword `ssh -p 22 zonesync@slave.ip.address`

### Install zoneSync
  1. On Master:
    * Change to user zonesync (if not already logged in as zonesync user): `su - zonesync`
    * Get latest version of zoneSync: `git clone https://github.com/truenegative/zonesync.git`
    * Open up zonesync/zonesync.sh with vi or nano and change the variables at the beginning to match your slave server IP address and bind configuration.
    * Ensure that the SLAVE.IP.ADDRESS is in the allow-transfer and also-notify section of the main named.conf.
  
  2. On Slave:
    * Create zonesync folders: `mkdir -p /var/named/zonesync && mkdir -p /var/named/zonesync/slaves` ( (`NOTE`): Use /var/named/chroot/var/named for chroot'd bind installations)
    * Set permissions: `chown -R zonesync:named /var/named/zonesync && chmod -R 770 /var/named/zonesync`
    * Add zonesync config file to named config: `cat "include \"zonesync/zonesync.SLAVE.IP.ADDRESS.named.conf\";" >> /etc/named.conf`
    
  
  3. Verify:
    * On Master (as zonesync user) run: `./zonesync.sh` and check for any errors. If you get the message `Successful synchronization to SLAVE.IP.ADDRESS.` move on to the next step.
    * On Slave, verify that /var/named/zonesync/zonesync.SLAVE.IP.ADDRESS.named.conf exists and is correct. If everything looks good, restart named: `service named restart`
  
  4. Set up a cronjob on the master to run every 15 mins or so:
    * `5,20,35,50 * * * * /home/zonesync/zonesync/zonesync.sh > /home/zonesync/zonesync/log/zonesync.log`
  
  5. Enjoy!

### Slave to Slave Replication
1.  Edit original Master and add secondary's ip address to the allow-transfer and also-notify sections of named.conf.

2.  Install zoneSync on first Slave:
   * Change to user zonesync (if not already logged in as zonesync user): `su - zonesync`
   * Get latest version of zoneSync: `git clone https://github.com/truenegative/zonesync.git`
   * Open up zonesync/zonesync.sh with vi or nano and change the variables at the beginning to match your slave server IP address and bind configuration.
   * Ensure that the SLAVE.IP.ADDRESS is in the allow-transfer and also-notify section of the main named.conf.

3.  On secondary slave:
   * Create user zonesync: `useradd zonesync && passwd zonesync`
   * Modify user zonesync: `usermod -G named zonesync`
   * Create zonesync folders: `mkdir -p /var/named/zonesync && mkdir -p /var/named/zonesync/slaves` ( (`NOTE`): Use /var/named/chroot/var/named for chroot'd bind installations)
   * Set permissions: `chown -R zonesync:named /var/named/zonesync && chmod -R 770 /var/named/zonesync`
   * Add zonesync config file to named config: `cat "include \"zonesync/zonesync.SLAVE.IP.ADDRESS.named.conf\";" >> /etc/named.conf`

4.  Verify slave to slave
   * On Slave (as zonesync user) run: `./zonesync.sh` and check for any errors. If you get the message `Successful synchronization to SLAVE.IP.ADDRESS.` move on to the next step.
   * On Secondary Slave, verify that /var/named/zonesync/zonesync.SLAVE.IP.ADDRESS.named.conf exists and is correct. If everything looks good, restart named: `service named restart`

5.  Set up cronjob on Slave to sync to Secondary Slave a few minutes apart from original cronjob
   * `7,22,37,52 * * * * /home/zonesync/zonesync/zonesync.sh > /home/zonesync/zonesync/log/zonesync.log`


### Thanks!

Thanks to everyone who I've bugged to get this working over the last few years. You guys know who you are! If you have some ideas for this or would like to see an additional feature added, submit an issue and we'll see what we can do about getting it included.

If you would like to help contribute to this project, feel free to submit pull requests and help out!


### About TN Labs

TN Labs is the brainchid of hosting company, [True Negative](https://truenegative.com) that develops web apps, mobile apps, and more. The TN Labs community is a place where you can find information on our in-house apps, games & more, our open-source projects, as well as a collection of various development & system administration tutorials.

[![Twitter Follow](https://img.shields.io/twitter/follow/tn_labs.svg?style=social&label=Follow&maxAge=2592000?style=flat-square)]()

##### Last Updated 2016/09/06
