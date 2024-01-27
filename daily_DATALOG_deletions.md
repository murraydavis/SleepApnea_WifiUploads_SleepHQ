## How to download only today's CPAP data

### getdata_ezshare.sh

When you run the get_ezdata.sh script each day, the previous night's data is downloaded and written to the DATALOG folder with a name reflecting a time stamp. For example, if today is January 25, 2004, all data from the previous night is written to a folder called: 20240124. This data is never removed. Future downloads just accumulate in the DATALOG folder. The next day's data are written as: 20240125 and 20240126 and so on. Is this an issue? Yes, it is. Each of these data folders is 3Mb in size. A month's accumulation would amount to over 90Mb of data.

```
rpi@cpap:~/cpapsrc/AirSense11-Data/DATALOG $ du -sh 20240124/
3.0M	20240124
```

Each day you will be copying from RPi an additional 3Mb of data. In a week, you will be copying 21Mb of data from your RPi machine to your home PC. You will also be uploading this same data from your home PC to the SleepHQ website. This copy process is very inefficient. Each day, you only need to copy the previous night's data. Without addressing the daily accumulation of data, the RPi DATALOG folder will continue to grow and the copy process will take more time.

### The solution on RPi and your home PC is to add a find command.

All we need to do is add one line to getdata_ezshare.sh on RPi and one line to your getcpap.sh script on your home PC.

```
# Add this line at the end of getdata_ezshare.sh. Use vi to open and edit the script. After you open the script hold down the shift key and then press g and a. The 'shift g' takes you to the last line and 'shift a' takes you to the end of this line. Hit the enter key and you are now in insert mode to add/paste the find command.
#
# Note, your path names may be different, modify accordingly.
#
# find /home/rpi/cpapsrc/AirSense11-Data/DATALOG/ -type d ! -wholename $(find /home/rpi/cpapsrc/AirSense11-Data/DATALOG/ -type d -printf '%T+ %p\n' | sort -r | head -1 | cut -d" " -f2) ! -wholename "/home/rpi/cpapsrc/AirSense11-Data/DATALOG/" -exec rm -r {} +
#
rpi@cpap:~/cpapsrc $ vi wget.sh # Add the find command and :wq to save the changes and exit.

rpi@cpap:~/cpapsrc $ tail -1 getdata_ezshare.sh # Display the last line of getdata_ezshare.sh.

find /home/rpi/cpapsrc/AirSense11-Data/DATALOG/ -type d ! -wholename $(find /home/rpi/cpapsrc/AirSense11-Data/DATALOG/ -type d -printf '%T+ %p\n' | sort -r | head -1 | cut -d" " -f2) ! -wholename "/home/rpi/cpapsrc/AirSense11-Data/DATALOG/" -exec rm -r {} +
```

On your home PC, we have to modify the script that is scheduled to run each morning according to crontab.

```
[DATALOG]$ crontab -l
30 7 * * *  /home/mgd/scripts/getcpap.sh >> /home/mgd/.var/log/cronlog/mycron.log 2>&1

# Display the current contents of getcpap.sh.

[scripts]$ cat getcpap.sh
sshpass -f /home/mgd/cpapdst/rpipass ssh rpi@192.168.50.224 /home/rpi/cpapsrc/getdata_ezshare.sh
sshpass -f /home/mgd/cpapdst/rpipass scp -r rpi@192.168.50.224:/home/rpi/cpapsrc/AirSense11-Data/* /home/mgd/cpapdst/AirSense11-Data

$ Using vi, edit getcpap.sh and add the find command to remove all but today's data.

[scripts]$ cat getcpap.sh
sshpass -f /home/mgd/cpapdst/rpipass ssh rpi@192.168.50.224 /home/rpi/cpapsrc/getdata_ezshare.sh
sshpass -f /home/mgd/cpapdst/rpipass scp -r rpi@192.168.50.224:/home/rpi/cpapsrc/AirSense11-Data/* /home/mgd/cpapdst/AirSense11-Data
find /home/mgd/cpapdst/AirSense11-Data/DATALOG/ -type d ! -wholename $(find /home/mgd/cpapdst/AirSense11-Data/DATALOG/ -type d -printf '%T+ %p\n' | sort -r | head -1 | cut -d" " -f2) ! -wholename "/home/mgd/cpapdst/AirSense11-Data/DATALOG/" -exec rm -r {} +

```

#### What does this find command do?

There are two components. The first part is the find command:

```
find /home/rpi/cpapsrc/AirSense11-Data/DATALOG/ -type d ! -wholename $(find /home/rpi/cpapsrc/AirSense11-Data/DATALOG/ -type d -printf '%T+ %p\n' | sort -r | head -1 | cut -d" " -f2) ! -wholename "/home/rpi/cpapsrc/AirSense11-Data/DATALOG/"
```

You can run this command by itself to test it and make sure that you have copied/edited the command correctly.  This find command will list all folders except the most recent folder. Let's test it by starting with an empty DATALOG directory and creating three folders.

```
# On RPi, create three new folders in a test folder.

rpi@cpap:~ $ mkdir test
rpi@cpap:~ $ cd test
rpi@cpap:~/test $ mkdir 20240119
rpi@cpap:~/test $ mkdir 20240120
rpi@cpap:~/test $ mkdir 20240121

# Get a detailed listing of each folder. Note, the only time stamp is H:M, no seconds.

rpi@cpap:~/test $ ls -la
total 20
drwxr-xr-x  5 rpi rpi 4096 Jan 26 15:32 .
drwxr-xr-x 18 rpi rpi 4096 Jan 26 15:31 ..
drwxr-xr-x  2 rpi rpi 4096 Jan 26 15:32 20240119
drwxr-xr-x  2 rpi rpi 4096 Jan 26 15:32 20240120
drwxr-xr-x  2 rpi rpi 4096 Jan 26 15:32 20240121

# Let's use a truncated version of our find command.

rpi@cpap:~/test $ find -type d -printf '%T+ %p\n'
2024-01-26+15:32:19.2841555820 .
2024-01-26+15:32:16.8041586250 ./20240120
2024-01-26+15:32:19.2841555820 ./20240121
2024-01-26+15:32:12.3141641340 ./20240119

# The above command also lists the parent directory. That is why in our find command we use a trailing / in each path. If you did not have the trailing slash, the '-exec rm -r {} +' part of the command would delete the parent directory, DATALOG.

# There is another command that gives detailed time information, the stat command.

rpi@cpap:~/test $ stat 20240119
  File: 20240119
  Size: 4096      	Blocks: 8          IO Block: 4096   directory
Device: b302h/45826d	Inode: 261960      Links: 2
Access: (0755/drwxr-xr-x)  Uid: ( 1001/     rpi)   Gid: ( 1001/     rpi)
Access: 2024-01-26 15:32:12.314164134 -0800
Modify: 2024-01-26 15:32:12.314164134 -0800
Change: 2024-01-26 15:32:12.314164134 -0800
Birth: 2024-01-26 15:32:12.314164134 -0800

rpi@cpap:~/test $ find -type d -printf '%T+ %p\n'
2024-01-26+15:32:19.2841555820 .
2024-01-26+15:32:16.8041586250 ./20240120
2024-01-26+15:32:19.2841555820 ./20240121
2024-01-26+15:32:12.3141641340 ./20240119
rpi@cpap:~/test $

# We can see that the find command timestamp for the folder 20240119 corresponds to the timestamp of the stat command.
```

Let's take a look at the '-exec rm -r {} +' part of the find command. Basically, that portion of the command says, run the remove (rm) command on the output of the find command. The string `{}' is replaced by the current file name being processed, that is, all the files/directories matching the conditions specified by the find command. The + symbol is just an efficiency command. It says to build the intended targets as a concatenated item so that the remove command is executed only once instead of removing each match one at a time.

```
# Create a simple text file and then search for all files with a .txt extension.

rpi@cpap:~/test $ touch test.txt
rpi@cpap:~/test $ touch test1.txt
rpi@cpap:~/test $ find *.txt -printf '%T+ %p\n'
2024-01-27+08:52:31.3775784340 test1.txt
2024-01-27+08:48:10.6678983150 test.txt

# Delete all .txt files, but add the verbose switch so that we can see what takes place.

rpi@cpap:~/test $find *.txt -printf '%T+ %p\n' -exec rm -vr {} +
rpi@cpap:~/test $ find *.txt -printf '%T+ %p\n' -exec rm -vr {} +
2024-01-27+08:52:31.3775784340 test1.txt
2024-01-27+08:48:10.6678983150 test.txt
removed 'test1.txt'
removed 'test.txt'
rpi@cpap:~/test $ ls
20240119  20240120  20240121

# Repeat the process, but create three text files and use our complete command to ensure that all text files except the last one created are deleted.

rpi@cpap:~/test $ touch {a..c}.txt
rpi@cpap:~/test $ ls
a.txt  b.txt  c.txt

# Each file appears to have the same timestamp: H:M:S.

rpi@cpap:~/test $ find -type f -printf '%T+ %p\n'
2024-01-27+09:09:55.9462967900 ./a.txt
2024-01-27+09:09:55.9462967900 ./c.txt
2024-01-27+09:09:55.9462967900 ./b.txt

$ Let's run our command, searching for files instead of directories and deleting all but the most recent file.

rpi@cpap:~/test $ find /home/rpi/test/ -type f ! -wholename $(find /home/rpi/test/ -type f -printf '%T+ %p\n' | sort -r | head -1 | cut -d" " -f2) ! -wholename "/home/rpi/test/" -exec rm -r {} +

rpi@cpap:~/test $ ls
c.txt

# Obviously c.txt was created last and thus is the most recent file.
```

### Final comments

This is a perfect solution that eliminates copying DATALOG data over WiFi each day that has already been copied in previous days. We only want to copy last night's data. The previous DATALOG data is removed on RPi and your home PC. The DATALOG data remains on the ezShare WiFi SD card. Currently, I just periodically take this SD card to my home PC and manually delete the data. I am trying to find a solution to automate this process.



