## Automate All Steps Using Cron Scheduler

### cron and anacron

Both [Cron and Anacron](https://docs.fedoraproject.org/en-US/fedora/latest/system-administrators-guide/monitoring-and-automation/Automating_System_Tasks/) can schedule execution of recurring tasks to a certain point in time defined by the exact time, day of the month, month, day of the week, and week. Cron jobs can run as often as every minute. However, the utility assumes that the system is running continuously and if the system is not on at the time when a job is scheduled, the job is not executed. On the other hand, Anacron remembers the scheduled jobs if the system is not running at the time when the job is scheduled. The job is then executed as soon as the system is up. However, Anacron can only run a job once a day. Also note that by default, Anacron only runs when your system is running on AC power and will not run if your system is being powered by a battery; this behavior is set up in the /etc/cron.hourly/0anacron script.

I decided to implement a cron solution. The anacron feature of running as soon as the system is available should a system be down at the scheduled time to run would be nice. I always leave my laptop running. It is very unlikely that it would be offline at 8:00 a.m. in the morning. I was also more familiar with configuring cron. The cron package is called: cronie. The anacron package is called: cronie-anacron. The command used to control cron jobs is, crontab.

There are scheduled system jobs on any PC. This document does not cover how to modify or look at those jobs. The document is focused only on creating a scheduled job for a user account.

I am going to confuse some people. I found it awkward to keep having to edit my documentation to change my user account to captain. My user account on my laptop is actually mgd. Therefore, from now on, you will see the account mgd, not captain. As well, the IP scope of my network is: 192.168.50.0/24. The IP address of RPi is 192.168.50.224 and the IP address of my laptop is 192.168.50.13.

### CRON

```
# Are the cron/anacron packages installed?

[~]$ rpm -q cronie cronie-anacron
cronie-1.6.1-5.fc39.x86_64
cronie-anacron-1.6.1-5.fc39.x86_64

# Is the crond service running?

[~]$ systemctl status crond
● crond.service - Command Scheduler
     Loaded: loaded (/usr/lib/systemd/system/crond.service; enabled; preset: enabled)
    Drop-In: /usr/lib/systemd/system/service.d
             └─10-timeout-abort.conf
     Active: active (running) since Thu 2023-12-21 09:27:37 PST; 1 day 4h ago
   Main PID: 1548 (crond)
      Tasks: 1 (limit: 9371)
     Memory: 1.2M
        CPU: 1.591s
     CGroup: /system.slice/crond.service
             └─1548 /usr/sbin/crond -n

# Do I have any schedule jobs?

cron.d]$ crontab -l
no crontab for mgd
```

### First step, create the script (remember, make it executable) that you want to run each morning on your home PC. Put the script in your scripts directory (that you added to your $PATH variable). I will first give you a simple form of the script, getcpap.sh. This is likely all you will need. You, of course, will need to change the IP address of RPi to match your settings as well as change the account names and folder paths, if different than mine.

```
[scripts]$ cat getcpap.sh
    sshpass -f /home/mgd/cpapdst/rpipass ssh rpi@192.168.50.224 /home/rpi/cpapsrc/getdata_ezshare.sh
    sshpass -f /home/mgd/cpapdst/rpipass scp -r rpi@192.168.50.224:/home/rpi/cpapsrc/AirSense11-Data/* /home/mgd/cpapdst/AirSense11-Data
```

As you see from above, there are only two commands in the script. The first command runs the getdata_ezshare.sh script on RPi. This script connects to the ezShare WiFi network and pulls the data from the ezShare SD card, reconnects to your home network, and finally renames STR.EDF. The second command copies the data from RPi to your home PC. Each command uses the password file that contains rpi's password. Each command also uses ssh to connect to RPi.

#### A variation of getpap.sh that addresses a network issue.

I have a wonky network issue that I have never been able to resolve. Connections between nodes in my network sometimes simply drop. I have researched and troubleshot this issue for the past couple of years. Likely suspects are usually duplicate IPs, incorrect routes, faulty NICs, rogue DHCP servers, etc. I have not found the root cause. The only work around in my network scripts is to test if a route exists to the PC to which I want to connect. From my laptop, before I run my sshpass commands, I test if there is a route to RPi whose IP address is 192.168.50.224. If there is no route, I add the route. If there is a route, I simply run the commands.

[scripts]$ cat getcpap.sh
## add route to cpap if doesn't exist

EXIST=`ip route show 192.168.50.224 | wc -l`
# EXIST = 1 if route exists, EXIST = 0 if route does not exist
if [ $EXIST -eq 0 ]
then
    sudo ip route add 192.168.50.224 via 192.168.50.1
    sshpass -f /home/mgd/cpapdst/rpipass ssh rpi@192.168.50.224 /home/rpi/cpapsrc/wget.sh
    sshpass -f /home/mgd/cpapdst/rpipass scp -r rpi@192.168.50.224:/home/rpi/cpapsrc/AirSense11-Data/* /home/mgd/cpapdst/AirSense11-Data
fi
if [ $EXIST -eq 1 ]
then
    sshpass -f /home/mgd/cpapdst/rpipass ssh rpi@192.168.50.224 /home/rpi/cpapsrc/wget.sh
    sshpass -f /home/mgd/cpapdst/rpipass scp -r rpi@192.168.50.224:/home/rpi/cpapsrc/AirSense11-Data/* /home/mgd/cpapdst/AirSense11-Data
fi

### Second step, create the cronjob.

1. Cronjobs are created, edited and displayed using the crontab command.

```
# The line that we want to add is the following. This line says to run our script each day at 8:00 a.m. every day.

0 8 * * *  /home/mgd/scripts/getcpap.sh

# Open the crontab editor. The default crontab editor on Fedora is nano.

[~]$ crontab -e

# After you add the line, CTRL-s to save the document and then CTRL-x to exit. Then list your scheduled job.

[~]$ crontab -l
0 8 * * *  /home/mgd/scripts/getcpap.sh
```

So, you are basically done. Now, the data copies happen automatically each morning at 8:00 a.m.

### LOGROTATE

Here are two resources that explain the command, logrotate. One from [Open Source](https://opensource.com/article/21/10/linux-logrotate) and one from [Digital Ocean](https://www.digitalocean.com/community/tutorials/how-to-manage-logfiles-with-logrotate-on-ubuntu-20-04). We need logrotate in order to build a limited number of compressed log archives. Without logrotate, your logs will continue to grow as you run your script if you pipe the output to a logfile.

```
# Here is my actual crontab job...

[~]$ crontab -l
0 8 * * *  /home/mgd/scripts/getcpap.sh >> /home/mgd/.var/log/cronlog/mycron.log 2>&1
```

The output that normally would be displayed at the terminal when you run getcpap.sh is appended to a file called mycron.log. At the end of the command is a redirect to [stderr/stdout](https://stackoverflow.com/questions/818255/what-does-21-mean). In order to use the log file, I have to first create two directories in my .var directory.

```
# Create the log and cronlog  direcories.

[~]$ mkdir -p /home/mgd/.var/log/cronlog

# Create the logfile.

[~]$ touch /home/mgd/.var/log/cronlog/mycron.log

# ls the full path to mycron.log to verify that the directories and logfile were created correctly.

[~]$ ls -la /home/mgd/.var/log/cronlog/mycron.log
-rw-rw-r--. 1 mgd mgd 4905 Dec 23 08:00 /home/mgd/.var/log/cronlog/mycron.log

[~]$ cat /home/mgd/.var/log/cronlog/mycron.log
[~]$
```

Now that have an empty mycron.log logfile, we can now configure logrotate. What version of logrotate is on my Fedora 39 box?

```

[~]$ logrotate --version
logrotate 3.21.0

    Default mail command:       /bin/mail
    Default compress command:   /bin/gzip
    Default uncompress command: /bin/gunzip
    Default compress extension: .gz
    Default state file path:    /var/lib/logrotate/logrotate.status
    ACL support:                yes
    SELinux support:            yes
[~]$
```

Where are the system and user logrotate configuration files? On Fedora 39, they are in /etc/logrotate.d

```
[~]$ cd /etc/logrotate.d

[logrotate.d]$ ls
bootlog  dnf       firewalld  iodine-client  krb5kdc    libvirtd.qemu  numad    psacct   sssd
btmp     dpkg      glusterfs  iscsiuiolog    libreswan  lightdm        php-fpm  rsyslog  wpa_supplicant
chrony   firebird  httpd      kadmind        libvirtd   mysql          ppp      samba    wtmp

# Let's take a look at the numad logrotate config file to get an example of what a configuration file looks like.

[logrotate.d]$ cat numad
/var/log/numad.log {
    compress
    copytruncate
    maxage 60
    missingok
    rotate 5
    size 1M
}
```

Using the vi editor, I created a logrotate file called, mycronlog, as shown below.

```
[logrotate.d]$ cat mycronlog
/home/mgd/.var/log/cronlog/mycron.log {
  rotate 2
  weekly
  compress
  missingok
  notifempty
  create 0664 mgd mgd
}
```

The options used above are:

path: The first line is the full path to our logfile.
rotate 2: Keep two log files. This overrides the rotate 4 default.
weekly: Rotate once a week. The default is weekly.
compress: Compress the rotated files. This uses gzip by default and results in files ending in .gz. The compression command can be changed using the compresscmd option.
missingok: Don’t write an error message if the log file is missing.
notifempty: Don’t rotate the log file if it is empty.
create 0664 mgd mgd: This creates a new empty log file after rotation, with the specified permissions (0664) expressed in octal form for owner (mgd), and group (also mgd).

In the README.md file, I discussed how permissions are used and displayed.

```
# Display the Read, Write, Execute permissions for owner, group, and other.

[~]$ ls -la /home/mgd/.var/log/cronlog/mycron.log
-rw-rw-r--. 1 mgd mgd 4905 Dec 23 08:00 /home/mgd/.var/log/cronlog/mycron.log

# Display these permissions as well as their octal equivalent.

[~]$ stat /home/mgd/.var/log/cronlog/mycron.log | grep -m 1 Access
Access: (0664/-rw-rw-r--)  Uid: ( 1000/     mgd)   Gid: ( 1000/     mgd)
```

The create command is just replicating the permissions on mycron.log that were applied when I created mycron.log.

That's it. We now have mycron.log on a two week cycle. There is no great need for too many logs. Either the script runs or it does not run.


### Troubleshooting - It is unlikely that you will have to follow these steps.

The first morning my script ran perfectly and my CPAP data was automatically uploaded to my laptop. The second morning the script failed. My old network issue came back to bit me in the ass. Here are the last two lines of mycron.log.

```
[~] tail -2 /home/.var/log/cronlog/mycron.log

/home/mgd/scripts/getcpap.sh: line 3: ip: command not found
RTNETLINK answers: File exists
```

So, what happened? Maybe I needed a sudo in front of line 3 of the getcpap.sh file? I changed line 3 to read...

```
[scripts]$ sed -n '3p' getcpap.sh
EXIST=`sudo ip route show 192.168.50.224 | wc -l`
```

I edited crontab to change the time to re-run the script. I then got this error in mycron.log.

```
[~]$ tail -5 /home/.var/log/cronlog/mycron.log
/home/mgd/scripts/getcpap.sh: line 3: ip: command not found
RTNETLINK answers: File exists
ssh: connect to host 192.168.50.224 port 22: No route to host
ssh: connect to host 192.168.50.224 port 22: No route to host
scp: Connection closed
```

Damn! Somehow RPi had reverted to the ezShare WiFi network. I needed a way to test the WiFi network on RPi before I ran my getcpap.sh script on my laptop. So, on RPi, I created a script called testwifi.sh and created a cronjob to run this script 5 minutes prior to running getcpap.sh on my laptop. I decided to first create the script directory and add its path to the $PATH variable in my .bashrc file and then source .bashrc

```
[~]$ mkdir scripts

[~]$ vi .bashrc
[~]$ cat .bashrc | grep scripts
export PATH="/home/rpi/scripts:$PATH"

# Display the contents of testwifi.sh

rpi@cpap:~/scripts $ cat testwifi.sh
#test which WiFi network

EXIST=`sudo nmcli -f GENERAL.STATE con show 'mywifinetwork' | wc -l`
# EXIST = 1 if home WiFi network up, EXIST = 0 if homw WiFi network down
if [ $EXIST -eq 0 ]
then
    sudo nmcli connection up 'mywifinetwork'
    sudo ip route add 192.168.50.13 via 192.168.50.1
fi
if [ $EXIST -eq 1 ]
then
    echo -n # i.e., do nothing
fi

# Do I have any cronjobs?

rpi@cpap:~ $ crontab -l
no crontab for rpi

# What is the default editor? None!
rpi@cpap:~ $ echo $EDITOR

# Run the crontab editor for the first time. I selected option 2, vim.tiny, vi being my preferred editor.

rpi@cpap:~ $ crontab -e
no crontab for rpi - using an empty one

Select an editor.  To change later, run 'select-editor'.
  1. /bin/nano        <---- easiest
  2. /usr/bin/vim.tiny
  3. /bin/ed

Choose 1-3 [1]: 2
crontab: installing new crontab

# At this point, I am taken inside the vi editor so that I could add the line that I needed.

rpi@cpap:~ $ crontab -l
55 7 * * *  /home/rpi/scripts/testwifi.sh
```

I connected my peripherals on RPi and from the terminal connected to the ezShare network. I then ran testwifi.sh and it reconnected to my home WiFi network. I ran the script again and nothing happened because it was already connected to my home WiFi network. I then changed to the ezShare WiFi network, edited my crontab job so that it ran 5 minutes ahead and waited. The script ran successfully at the scheduled time and connected me back to the home WiFi network. Finally, a reliable solution for the wonky network issue.

















