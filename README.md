# zonesync
zoneSync is a bash script for synchronizing DNS records between masters and slaves. Originally a fork of nobaloney's master-slave script from the DirectAdmin forums, it has been changed and massaged into what it is now.

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
  2. On Master (As user zonesync)
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


##### Last Updated 2015/07/01
