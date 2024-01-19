#### Optional Configuration

### 1. Suppress SSH motd (message of the day) on RPi and your home PC (both Linux systems).

1.1 Edit the sshd_config config file and ensure that the line PrintMotd exists, is uncommented, and is set to no.
```
# You can open a file at a specific line using the +/searchterm option. The following command opens sshd_config at the PrintMotd line.

$ sudo vi +/PrintMotd /etc/ssh/sshd_config

# After making the changes, save and exit and then verify that the changes are correct.

$ grep PrintMotd /etc/ssh/sshd_config
PrintMotd no
```

1.2 Edit the /etc/pam.d/sshd file.
```
$ sudo vi +/pam.motd /etc/pam.d/sshd

# Find the following two lines and add the # symbol in front of each, i.e., turn the lines into comments. Save and exit.

session    optional     pam_motd.so  motd=/run/motd.dynamic
session    optional     pam_motd.so noupdate

# session    optional     pam_motd.so  motd=/run/motd.dynamic
# session    optional     pam_motd.so noupdate
```

1.3 Restart sshd
```
$ sudo systemctl restart ssh
```

A three step process? I found a simpler and more elegant solution.

```
# Start in your home directory and create an empty file called, .hushlogin. Any file beginning with a period is a hidden file. You need a special command to list those files. The cd command by itself takes you to your home directory.

[some other directory]$ cd
[~]$ touch .hushlogin

# I have an alias in my .bashrc file that lists hidden files.

[~]$ alias l.
alias l.='ls -d .* --color=auto'

So, let's list .hushlogin. I use the grep command because I have many hidden files.

[~]$ l. | grep .hushlogin
.hushlogin

[~]$ cat .hushlogin
[~]$
```

The presence of this hidden file by itself suppresses the SSH motd.

### 2. What if you have two or more users on RPi?

How do you configure RPi so that rpi gets logged on automatically after system reboots? RPi uses LightDM, a free and open-source X display manager that aims to be lightweight, fast, extensible and multi-desktop. To set rpi as the default user, you need to edit a single line in the LightDM configuration file: autologin-user. Use the sudo command to edit the configuration file. Note, this solution only works if you keep lightdm as the display manager. If you choose another display manager, the configuration changes will be specific to the new display manager.

```
$ sudo vi +/autologin /etc/lightdm/lightdm.conf

$ grep autologin /etc/lightdm/lightdm.conf
autologin-user=rpi
```

### 3. Does RPi connect automatically to the ezShare WiFi network after reboots?

The easiest solution is to create a script and place it in the /etc/init.d directory. This is the startup directory. Any scripts in this directory are executed on reboots. Create and save this script using the sudo and vi commands. You will be adding two nmcli commands.

```
$ sudo vi /etc/init.d/updwn.sh

$ sudo chmod +x /etc/init.d/updwn.sh

$ sudo cat /etc/init.d/updwn.sh
sudo nmcli connection down 'ez Share'
sudo nmcli connection up mywifinetwork
```

### 5. Issues with ssh, an explanation as to why I added Step 19

I upgraded my home PC from Fedora 38 to Fedora 39. I also updated RPi. I may have corrupted something during the process because I could no longer SSH to my home PC from /RPi. Here is the error I received:

rpi@cpap:~ $
sshpass -f /home/rpi/cpapsrc/scppassfile ssh mgd@192.168.50.13
kex_exchange_identification: read: Connection reset by peer
Connection reset by 192.168.50.13 port 22

There are many websites that attempt to address the issue, but none seemed to work. One of the things that I looked at was the version of sshd on my home PC and on RPi.

```
[homePC] $ ssh -V
OpenSSH_9.3p1, OpenSSL 3.1.1 30 May 2023

rpi@cpap:~ $ ssh -V
OpenSSH_8.4p1 Raspbian-5+deb11u2, OpenSSL 1.1.1w  11 Sep 2023
```

This seemed like a promising lead, but then I successfully tested SSHing into my home PC from another Raspberry Pi box that had the same version of OpenSSH. After much frothing around I realised that the I was trying to run an SSH command back to my home PC from RPI to which I had already connected via SSH. This led me to create the document, cron_logrotate.md. The solution was to run/invoke both copy commands from my home PC. I highly recommend following my instructions in the cron_logrotate.md document.

### 6. SSH - client_loop: send disconnect: Broken pipe

One morning, after 8:00 a.m., I uploaded my data to Oscar, but discovered that there was no new data. I checked my logfile and discovered the following.

```
[cronlog]$ tail -10 mycron.log
Updated file added to downloads: DATALOG/20231223/20231224_033113_BRP.edf
Scan of dir=A:SETTINGS
Updated file added to downloads: STR.EDF
1031 File(s) scanned in 43 Folder(s)
Downloading of 10 Files in progress, Please Wait...
1 New(s) file(s) downloaded
9 File(s) Updated
Completed in 20 seconds
Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/43)
client_loop: send disconnect: Broken pipe
```
The first part of the getdata.sh script worked. RPi downloaded the morning's data from my AS11, but then the SSH connection dropped and the second command did not run. I had to manually run the second command of the getdata.sh script in order to copy the data from RPi to my laptop.

I found the following [webpage](https://www.tecmint.com/client_loop-send-disconnect-broken-pipe/) which clearly laid out the background and solution to the problem. To prevent this issue from arising in the future, I edited the sshd_config file on RPi, as explained in the article; uncommented and changed the ClientAlive statements, and restarted the sshd service.

```
# Use vi to open and edit sshd_config

rpi@cpap:~ $ sudo vi +/ClientAlive /etc/ssh/sshd_config

rpi@cpap:~ $ grep ClientAlive /etc/ssh/sshd_config
ClientAliveInterval 300
ClientAliveCountMax 3

rpi@cpap:~/cpapsrc $ sudo systemctl restart sshd
```

### 7. Change the default editor on Fedora

```
[~]$ echo $EDITOR
/usr/bin/nano

# Add the following line to your .bashrc file,

[~]$ echo 'export VISUAL="/usr/bin/vi"' >> /home/mgd/.bashrc

# Reload .bashrc

[~]$ source .bashrc

# When your open crontab, the editor is now vi.

# After I did all the above, the $EDITOR value remained nano, maybe a logon/off or reboot is needed.

[~]$ echo $EDITOR
/usr/bin/nano
```



