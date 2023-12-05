## Sleep Apnea Data WiFi Uploads to SleepHQ

### Nomenclature

1. I refer to the Raspberry Pi PC as: RPi.

2. I refer to the ez Share SD card as: ezShare.

3. The default SSID of ezShare is: ez Share, note the space after the z.

4. The default sudo user on my RPi is: rpi (all lower case).

5. The full path to the cpap working directory on RPi is: /home/rpi/cpapsrc. In this directory is the cpap data folder: AirSense11-Data.

6. The full path to the cpap working directory on my home PC is: /home/captain/cpapdst. In this directory is the cpap data folder: AirSense11-Data, with its contents copied from RPi.

7. The home network is 192.168.1.0/24. The IP address of RPi on this network is 192.168.1.20. The IP address on the home PC is 192.168.1.5.

8. The ezShare hotspot is on a different network, 192.168.4.0/24. The ezShare IP address is 192.168.4.1. 

9. The ezShare hotspot has three network services: WiFi, DNS, and DHCP. DHCP hands out IP addresses to clients on its WiFi network, 192.168.4.0/24. The IPs that it hands out range from 192.168.4.2 to 192.168.4.254.

10. The ezShare WiFi network does not connect to the Internet. The ezShare does not facilitate connectivity between devices/clients on its WiFi network, only between itself and its DHCP client devices, even though it broadcasts its DNS server IP of 192.168.4.1 (itself).

10. The first device that connects to its WiFi gets the 1st IP address, 192.168.4.2. In my case, my iPhone was the 1st device to connect to its WiFi network, so it got that address. RPi was the second device to connect, so it got 192.168.4.3 as its IP address.

11. There is only one port open on ezShare. From my iPhone, I scanned all well-know ports, 1-65353. The only port open was port 80 (http).

12. A WiFi scan reveals the following info for the ezShare card WiFi network: 2.4GHz channel only (no 5 GHz), the Mac-Address of my SD card is: FA:55:95:11:30:D0 (your MA will be different, this is a manufacturer's hard-coded address), channel: 11, privacy: TKIP, cipher: CCMP, signal: -74 (a radio power indicator, varies over time), security: wpa/wpa2.

### Purpose

This is a how to document explaining how to build a RPi to capture sleep apnea data from an ezShare WiFi SD card (that has been inserted into the SD slot on a ResMed Airsense11 CPAP machine) and then upload that data to the [SleepHQ](https://sleephq.com) app/website and the [Oscar](https://www.apneaboard.com/wiki/index.php/OSCAR_-_The_Guide) app.  I only use the Oscar app as a troubleshooting tool if I encounter a rare upload issue on the SleepHQ site. The SleepHQ site is vastly superior in terms of clarity of design and comprehensive features...as well as having a vibrant community forum and exceptional customer support. The methods outlined in this document should work for any sleep apnea device that writes data to a SD card.

### Acknowledgements

I would first like to acknowledge all the hard work that Adsy and Uncle Nicko (sleephq.com) and their small team put into the development of the [Magic Uploader](https://www.sleephq.com/product/magic-uploader/). I am not advocating a replacement for their commercial product. In fact, this document may drive sales for SleepHQ. There may be SleepHQ members who start reading this document and conclude, "No way am I going to try that! I will buy a Magic Uploader."

I simply wanted to see if I could devise a way to use my own Raspberry Pi box to accomplish some of the tasks performed by SleepHQ's Magic Uploader. I am proud to be a founding member of the SleepHQ community because I was an early subscriber to premier membership. I am excited about the future of SleepHQ which was well outlined by Uncle Nicko in his Nov. 21, 2023 newsletter, SleepHQ 12 Month Anniversary. 

The goal of my solution was to use the same platform as the Magic Uploader, an RPi PC, and to eliminate the [cpap sneakernet](https://en.wikipedia.org/wiki/Sneakernet) process of taking the SD card out of the Resmed device each morning, walking to my laptop, inserting the SD card into my USB hub, uploading the files to SleepHQ and removing the SD card and walking it back to the Resmed machine and inserting the SD card back into its SD slot---a royal pain. Sometimes I forgot to complete the cycle and would end up with no data recording the next morning because my SD card was still sitting in the SD slot of my USB hub. Gone also is the necessity of guessing when the ResMed AirSense11 writes its data to its SD card at some point after taking off the CPAP mask...a rather hit and miss proposition. If you guess incorrectly and remove the SD card too early, no data gets written to the SD card even after you reinsert the SD card.

I relied heavily on Marty Martin's [DIY Not-So Magic Uploader](https://community.sleephq.com/c/ask-for-help/diy-not-so-magic-uploader) post found on the SleepHQ community website. The source for the bash script which Marty referenced is [jimbocococo](https://github.com/jimbocococo/EzShare-SdcardWifi-Downloader), a GitHub repository.

### Why a Raspberry Pi?

You do not have to use a Raspberry Pi box. You could use any computer, a desktop, a laptop, or any small form factor PC from a vendor such as [Beelink](https://www.bee-link.com/). These are the main features that make the Raspberry Pi the most suitable box. 

1. It is the cheapest alternative.

2. It has the smallest, most compact size.

3. The base operating system is Debian Linux. There is a wealth of resources on the Internet about how to manage the Debian. 

4. The Raspberry Pi is used in schools and academics settings of higher learning. It has many scientific and business applications (Magic Uploader). As well, there are large communities of hobbyists who build Raspberry Pi boxes to function as media servers, music streamers, print servers, robotic controllers, etc. There are tons of Internet resources on using the Raspberry Pi.

5. Building a Raspberry Pi from its installer program, Raspberry Pi Imager, is very quick. It should take under 5 minutes to install. So, if you mess up, simply rebuild your RPi.

6. RPi is very resilient. Hard crashes or manual power offs are very unlikely to harm your system.

### Challenges for the SleepHQ Community

The process of creating this how to document took longer to write/edit than finding the solution to build and perfect my own Magic Uploader. The challenge for the reader is to learn and apply some basic Linux command line skills. The challenge for me was to create a document that would be easy to follow for the average user. In the end, I think the target audience will be rather narrow, the technologically savvy or adventurous. The process of getting the CPAP data to SleepHQ using only WiFi is outlined in the following steps, the steps of the Getting the data section:

1. Purchase an ezShare SD card (step 1), RPi PC (step 2), and SD card adapter and micro SD card (step 3).

2. Using Raspberry Pi Imager, build the RPi operating system (step 4) with a custom configuration by flashing it to a micro SD card.

3. Put the micro SD card into the micro SD slot on RPi and boot (step 5). Update RPi (step 7)

4. Enable VNC on RPi (step 8). Install Network Manager on RPi and enable it (step 9).

5. Create destination folders for the CPAP data on RPi and the home PC (step 10).

6. Download to your home PC getdata_ezshare.sh from my GitHub repository (step 11) and modify it (step 12).

7. Copy the modified getdata_ezshare.sh from your home PC to RPi (step 13).

8. SSH to RPi and make getdata_ezshare.sh executable (step 14).

9. Run getdata_ezshare.sh to copy the CPAP data from the ezShare SD card to RPi and then copy that data to your home PC (step 15).

10. Now that you have the data on your home PC, copy the data to SleepHQ, step 16 or 17.

11. Simplify the data collection, run the script from our home PC and eliminate the need to SSH into RPi in order to run the script, step 18.

### The solution reduced to its simplest form.

For those skilled in Linux, you have just four basic tasks:

1. Download getdata_ezshare.sh from my Github repository (step 11).

2. Edit this script by making changes to 7 lines of code (step 12).

3. Run the script to get the data (step 15).

4. Copy the data to the SleepHQ site (step 16/17/18), step 18 preferred.

### Linux

The operating system on RPi mini-PC's is Debian, a free and open operating system based on Linux. I run Fedora 37 on my laptop, another Linux operating system. You will need some understanding of Linux in order to apply this solution. I am in the process of creating a PDF that will clearly describe each step. I will include lots of screen shots and code dumps with explanations for each command. In an obvious bit of self-promotion, take a look at [Linux System Administration](https://github.com/murraydavis/Linux-System-Administration). The book is the document main.pdf compiled from many LaTex source files. I placed a copy of main.pdf on my [Sleep Apnea Repository](https://github.com/murraydavis/SleepApnea_WifiUploads_SleepHQ) renaming it to LinuxSystemAdministration.pdf. I wrote the book several years ago using the [LaTeX typesetting system](https://www.latex-project.org/). In the book, I introduce novices to the administration of the Linux operating system using the command line (centered on the Fedora operating system). Most Linux servers do not have a graphical user interface. The text-based command line is the only way of interacting with the server. The book is a bit out-of-date, but most of the content is still relevant. I wrote the book using LateX as an exercise to help me learn typesetting. Be aware that Linux commands vary between the various Linux (distros)[https://distrowatch.com/]. Commands/packages to perform the same task may vary between distros. For example, on RPi, which is a Debian distro, the commands to update the platform are: sudo apt get update && sudo apt upgrade; while on Fedora the update is accomplished with a single command: sudo dnf update.

### WiFi networks; a potential issue if your home network is the same as the ezShare WiFi network.

You will remotely access RPi using a command line tool called SSH, secure shell; or via a remote desktop app called VNC. The simplest way to access the RPi is to use its IP address. However, there is a an important issue of which you need to be aware. [Private IP4 networks](https://en.wikipedia.org/wiki/Private_network) have restricted formats like those IP addresses that your home router hands out (via DHCP) to all network clients such as your laptop and smart devices. If you are one of the rare (and unlikely) individuals who have a router whose network is 192.168.4.0/24, you will have to change that network. Why? The ezShare hotspot uses that network. You cannot have your home network and the hostpot network in the same IP range. The reason is related to routing and default gateways, a topic a bit broader than the scope of this document. Just logon to your WiFi router and change the DHCP scope from 192.168.4.0/24 to one of the other private IP4 networks. You will need to restart each device on your home network so that they get new IPs on the new network. This can also been done via the command line. Changing static IPs is a bit more complicated. If your IP address is on another IP scope, you do not have to do anything. 

### Getting the data

#### Step 1 Aquire an ezShare WiFi SD card.

Purchase an [32 GB ezShare WiFi SD card](https://www.aliexpress.com) or similar WiFi SD card on Amazon. This document is written for the ezShare SD card. If you purchase another vendor's card, the hotspot WiFi network and credentials will be different. If you are concerned about default security, change the admin password, SSID, SSID password (and WiFi channel, if your WiFi neighborhood is crowded) using the ezShare app (iOS or Android). Network security is not a huge issue. I am a bit paranoiac about security. I always change default settings for all network devices. Be aware that if you change the default settings on the ezShare SD card and then later reformat the ezShare card, your custom settings will be wiped and the default settings will return. When you run the getdata_ezshare.sh script on the RPi to get the data from the ezShare card, RPi only connects to the ezShare WiFi network for a very brief period. Typical download times are about 10-15 seconds. During those 10-15 seconds, it is unlikely that a hacker would have enough time to attack and compromise the RPi.

I live in a condo (steel and concrete construction). To test the range of the ezShare hotspot, I put my iPhone on the ezShare WiFi network and then opened a network app (surprisingly called Ping) and issued the ping command to the ezShare IP address, 192.168.4.1. I then went out into the hallway and walked down the hall until the ping responses stopped. I could get quite far, at least past three other suites. So, there is some risk of exposure, especially if you have a [blackhat hacker](https://en.wikipedia.org/wiki/Black_hat_(computer_security)) living adjacent to you. One can theoretically [hack or jailbreak](https://airbreak.dev/) into a ResMed device and flash its firmware, but you need local access, so there is no network risk for the ResMed device.

My ResMed AirSense11 and RPi are in our bedroom. Surprisingly, the ezShare WiFi signal is quite weak within our own suite. . It is hit or miss whether or not I can connect to the ezShare WiFi network using my laptop which is located in a non-adjacent room. I use my iPhone to run network tests because it is easier to take to and operate in the bedroom.

#### Step 2 Acquire a Raspberry Pi mini computer.

Purchase a Raspberry Pi mini computer on Amazon or from [Raspberry Pi](https://www.raspberrypi.com/). You can optionally purchase a case, mini monitor, KB, and mouse. I say optional for the case, but I think this is a "would be really, really nice to have option". You don't really need to attach a KB, mouse, and monitor to the RPi because you will likely always be interacting with the RPi via a remote VNC connection or a via the command line using Secure Shell. There are potential issues if you lose connection to RPi while it is on the ezShare network. See, Step 9.3. Note that the base RPi, without a case, has mounting screw holes so that the RPi can be mounted on the back of a monitor.

#### Step 3 Acquire a SD card adapter, micro SD card, and USB hub.

Acquire a SD adapter card and a 32 GB micro SD card and an external USB hub with an SD card slot. You need a micro SD card. The micro SD card is the hard drive for your RPi. The RPi has only one slot for a hard drive; for a micro SD card, not a standard SD card.

#### Step 4 Build RPi.

On your personal PC, install [Raspberry Pi Imager](https://www.raspberrypi.com/software/). Using this application, configure three options for your RPi: 

1. Raspberry Pi Device (the model you purchased in Step 2).

2. The Operating System (basically a choice between 32 and 64-bit Debian).

3. The storage (the location or path to your SD card). 

Your choice of a Raspberry Pi Device affects the options for the Operating System. Click Save after making changes on each tab and then click Next and choose Edit Settings. You then configure:

General Tab: hostname (I chose a hostname of cpap), username/password (I chose a username of rpi), configure the home WiFi/LAN network (SSID & password), set locale settings (time zone & kb layout). 

Services tab: enable SSH (Secure Shell). This is an essential step if you wish to run the RPi headlessly (no kb, no mouse, no monitor) and connect to it via an SSH terminal session. 

Options tab: By default eject media when finished is selected. You will then be given the option of choosing Yes/No to apply the settings. The RPi Imager application will automatically format the SD card, download the appropriate operating system, and configure your choices.

#### Step 5 Insert micro SD card into RPi.

Safely remove the SD card adapter and the micro SD card. Put the micro SD card into the micro SD slot of RPi. Power on to boot RPi. The are tons of videos describing how to insert the micro SD card, here is [one site](https://www.raspberrypi.com/documentation/computers/getting-started.html).

#### Step 6 Find the IP address of RPi and SSH to it.

If you run RPi headlessly, you will need a way to find its IP address on your home network. Use either a WiFi scanning app that identifies all the devices on your WiFi network or log into your WiFi router and identify RPi's IP address using its logging feature. Let's assume that you find that RPi's home network IP is 192.168.1.20.  Open a terminal and ssh into RPi using the following command (you are prompted for rpi's password that you established in step 4). The first time you SSH into a system from a terminal, you are presented with some info about the remote system.

```
[~]$ ssh rpi@192.168.1.20
rpi@192.168.1.20's password: 
Linux cpap 6.1.21-v7+ #1642 SMP Mon Apr  3 17:20:52 BST 2023 armv7l

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Thu Nov 30 09:54:11 2023 from 192.168.50.13
rpi@cpap:~ $ 

# The fact that the prompt is, username@hostname, tells you clearly that you are on a remote system.
# If you want to end an SSH session, use the logout command.

rpi@cpap:~ $ logout

# You are returned to the command prompt on your home PC.
[~]$

```

You can now verify your IP address on RPi by issuing one of these commands.

```
rpi@cpap:~ $ hostname -I
192.168.1.20

rpi@cpap:~ $ ifconfig | grep wlan0 -A1
wlan0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.1.20  netmask 255.255.255.0  broadcast 192.168.1.255
```

If you connect a KB, mouse, and monitor, open the terminal on RPi and issue the same commands:

#### Step 7 Update RPi's operating system.

The first thing that I always do on a new Linux system is to update it. 

```
# You must use the sudo command to upgrade. The && means run the second command only if the first command completes successfully.

# sudo means execute this command with 'super user' privileges. The raspi-imager program adds the default account, rpi, to the super user group.

# Is rpi a member of the sudo group? Yes, it is!

rpi@cpap:~ $ getent group sudo
sudo:x:27:rpi

rpi@cpap:~ $ sudo apt update && sudo apt upgrade

# After the upgrade has finished, you need to reboot.
# sudo shutdown -r now, also works.

rpi@cpap:~ $ sudo reboot
```

The command prompt provides some basic user/system information. From the left of a each line, everything up to and including the $ is the command prompt. For the above commands, we see that the logged on user is rpi. We also see that rpi has connected remotely to RPi whose hostname is cpap. rpi is currently in its home directory. The tilde symbol ~ is shorthand for home directory. The $ indicates that the logged on user is not the root user. If root was logged on, the symbol would be a #.
 
#### Step 8 Enable VNC on RPi.

ssh back into RPi. [Enable VNC](https://www.pitunnel.com/doc/access-vnc-remote-desktop-raspberry-pi-over-internet). You can now remotely VNC into the RPi desktop. You need a VNC app on your home PC. My VNC app is TigerVNC Viewer. VNC is just a way of remotely connecting to RPi to see and interact with its desktop.

#### Step 9 Install Network Manager on RPi.

You need to install the Network Manager application (sudo apt install network-manager) and enable it with raspi-config [by following these steps](https://pimylifeup.com/raspberry-pi-network-manager/#enabling-network-manager-on-the-raspberry-pi). Reboot. 

```
sudo apt install network-manager
sudo raspi-config
sudo reboot
```

You now have the nmcli terminal command on RPi. nmcli is used in the getdata_ezshare.sh script.

IMPORTANT: RPi will automatically connect to your home network because you configured it to do so in Step 4. In order to connect to the ezShare network, you must manually connect to that network using a VNC/desktop connection or via SSH from a command prompt.

##### 9.1 Connect to ezShare WiFi network using VNC.

On your home PC, launch VNC and enter the IP address of RPi. After you connect to the RPi desktop, click the WiFi symbol in the top right-hand corner. A list of available WiFi SSIDs will appear. Choose the ezShare network (ez Share) and provide its password, 88888888. This will add the ezShare network to the network configuration file that the command nmcli relies on. Unfortunately, as soon as you do this, you loose your VNC connection because you just switched RPi to the ezShare WiFi network and your home PC is still on the home WiFi network. You will now need to switch RPi back to your home network. Manually reboot or connect peripherals and repeat the above process but choose the home WiFi network from the WiFi SSID network list.

##### 9.2 Connect to ezShare WiFi network using SSH and run the nmcli command.

```
# SSH to RPi and get the list of available WiFi connections in your neighborhood.

rpi@cpap:~ $ sudo iwlist wlan0 scan | grep ESSID
                    ESSID:"IP_Freely"
                    ESSID:"SHAW-7EF850"
                    ESSID:"tonowhere"
                    ESSID:"Apple Network 401"
                    ESSID:"contortionist"
                    ESSID:"SHAW-6575B0"
                    ESSID:"ez Share"
                    ESSID:"SHAW-9DB7"
                    ESSID:"TheVic 2.4G"
                    ESSID:"DIRECT-vBC460 Series"
                    ESSID:"DIRECT-7n32-TS9100series"
                    ESSID:"SHAW-C732"
                    ESSID:""
                    ESSID:""
                    ESSID:"Primus96990"
                    ESSID:"TELUS2638"
                    ESSID:"TELUS4E61"
                    ESSID:"TELUS0586"
# # Or use this command, the output is more tabular: nmcli dev wifi list

# Many commands require sudo privileges. We can precede each of those commands with the keyword sudo.

# Why not switch to the super user account, root, instead of always typing sudo.

# Be careful, root is the most powerful account on a Linux system. You can kill your system using this account if you issue a command incorrectly (as you can with the sudo command). 

# Note, the prompt changes to root and the last character in the prompt is the number sign.

# All WiFi connection settings are in the directory: /etc/NetworkManager/system-connections

rpi@cpap:~ $ sudo -i

root@cpap:~# cd /etc/NetworkManager/system-connections

# contortionist.nmconnection is my home network, easy chair.nmconnection is my custom ezShare network, and ez Share.nmconnection is, of course, the default ezShare network.

root@cpap:/etc/NetworkManager/system-connections# ls
 'contortionist.nmconnection'  'easy chair.nmconnection'  'ez Share.nmconnection'

# Let's take a look at: ez Share.nmconnection. This file is created when you first connected to the ezShare WiFi network using the VNC method. This is not an encrypted file, it is a clear text file. It displays the SSID password. The \ after ez is an escape character. It means the following character is taken litterally. You need this \ because of the space in the name. Alternatively, put single quotes around the name: cat 'ez Share.nmconnection'

# The SSID is in the [wifi] section. The SSID password is in the [wifi-security] section.

root@cpap:/etc/NetworkManager/system-connections# cat ez\ Share.nmconnection 
[connection]
id=ez Share
uuid=e560ebdc-cddf-4816-831c-c12a257537e0
type=wifi
interface-name=wlan0
permissions=user:rpi:;

[wifi]
mac-address-blacklist=
mode=infrastructure
ssid=ez Share

[wifi-security]
auth-alg=open
key-mgmt=wpa-psk
psk=88888888

[ipv4]
dns-search=
method=auto

[ipv6]
addr-gen-mode=stable-privacy
dns-search=
method=auto

[proxy]

# Enter the following key-combination to exit as root user: CTRL-D, that is just the ctrl key and the letter d at the same time.
# You are now back logged on as rpi in the last working directory.

rpi@cpap:~ $

```

The command that we will need is the following:

sudo nmcli dev wifi connect network-ssid password "network-password"

Can we connect the first time to a WiFi network from the command line? The answer is, yes.

1. The hard way is to create the connection using the [nmcli interactive command](https://fedoraproject.org/wiki/Networking/CLI). I have never done this, but it looks quite possible. 

2. The easy way is just to provide the credentials to connect, using the nmcli command. The problem with doing it this way is that you will immediately lose your SSH connection because your home WiFi connection is dropped and you are switched to the ezShare WiFi network. Therefore, you need a work around as described below.

```
# When you connect to the ezShare WiFi network with the following command, you immediately lose connection.

rpi@cpap:~ $ sudo nmcli dev wifi connect 'ez Share' password "88888888"

# Boom, you are connected to the ezShare WiFI network.

# If this is the first time connecting to the ezShare WiFi network, a new connection entry is created in /etc/NetworkManager/system-connections

# Let's create a little script: create.sh (make sure you make it executable).

# We can create the script using a text editor or using the echo command.

# 1. Using a text editor like vi (there are many other text editors, vi just happens to be the most used).

# See Chapter 6 of my book, pages 147-167, for a quick overview of some of the basic vi commands. There is also an iPhone app called Vimmy which is a quick and dirt reference library.

# I will not show the steps to create the file using vi since the steps are a bit messy to document.

# 2. We could also simply create the new file using the echo command to add the lines of our file.

# We need the -e switch for edit. Note that each line subsequent to the first is separated by a backward slash and the letter n for newline.

# Also, pay attention to the use of the single and double quotes.

rpi@cpap:~ $ echo -e "sudo nmcli dev wifi connect 'ez Share' password "88888888"\nsudo nmcli connection up yourwifinetwork" > create.sh

# cat is a built-in command to display the contents of a file.

rpi@cpap:~ $ cat create.sh
sudo nmcli dev wifi connect 'ez Share' password "88888888"
sudo nmcli connection up yourwifihomenetwork

# Run the script as you normally would. 

# The 1st line of the script creates the new WiFi connection.

# The second line takes you back to your home WiFi network.

# There is a slight pause while the WiFi networks switch before your command prompt reappears.

rpi@cpap:~ $ ./create.sh

# Or, run the command like this...

rpi@cpap:~ $ bash create.sh
```

##### 9.3 Things can go wrong.

You can lose your SSH connection to RPi. A couple of times while experimenting and after connecting to RPi using SSH and running the getdata_ezshare.sh script, the command prompt did not return. Why did my script fail? Did the RPi shutdown? Was RPi still on the ezShare WiFi network? What to do? When I first started testing my script and switching between connections, I have a vague memory of successfully connecting (via SSH) to RPi after switching my laptop to the ezShare WiFi network. I then issued the command to switch back to the home WiFi network. I was then able to SSH into RPi on the home WiFi network after switching my laptop back to the home WiFi network. However, as I was finishing up my documentation, I tried to do repeat this process by sshing into RPi while it was on the ezShare WiFi network from both my iPhone and my laptop (which were both on the ezShare WiFi network). I could not ping or ssh to RPi. Like AI, did I hallucinate and falsely remember connecting to RPi on the ezShare WiFi network? I believe that I did hallucinate. The ezShare hotspot does hand out IP addresses in its network, 192.168.4.0/24. In my case, RPi gets the IP address, 192.168.4.3, the second IP address that got handed out because it was the second device that connected to the hotspot. My iPhone was the first so it got the address 192.168.4.2. ezShare also identifies itself as the default gateway, 192.168.4.1 as shown below. As discussed below, the ezShare WiFi card is not configured to allow inter-client communication.

```
rpi@cpap:~ $ ip route
default via 192.168.4.1 dev wlan0 proto dhcp metric 600 
192.168.4.0/24 dev wlan0 proto kernel scope link src 192.168.4.3 metric 600 
```

The ezShare hotspot hands out DNS info. But, again that info does not mean that the hotspot is connected to the Internet or that it will resolve IP addresses for you. It just establishes a connection between itself and its DHCP clients like RPi.

```
rpi@cpap:~ $ cat /etc/resolv.conf
# Generated by resolvconf
search EASYCARD
nameserver 192.168.4.1
```

The ezShare does not have routing capabilities, so you cannot route via it to connect to other devices on its network. That is why I believe you cannot SSH into RPi on the ezShare network.

In the end, you have three fail safe options to switch RPi back to the home WiFi network. 

1. Connect all the peripherals to RPi and work in the desktop environment. Open a terminal and issue the following command to switch back to the home network.

```
# First verify that you are indeed on the ezShare network. An IP address in the 192.168.4.0/24 says that you are.

rpi@cpap:~ $ hostname -I
192.168.4.3

# Now, switch to the homeWiFiNetwork, note the variation on the nmcli command.

rpi@cpap:~ $ sudo nmcli c up id homeWiFiNetworkSSID

# What's my IP? It is now in the homeWiFiNetwork IP range.

rpi@cpap:~ $ hostname -I
192.168.1.20
```

2. Instead of using the terminal, click the WiFi icon in the top right-hand corner and select the home WiFi network SSID.

3. Simply power off RPi by unplugging it. Don't worry, Linux is very resilient to hard boots! You will now be on the home WiFi Network and you can logon to its home WiFi Network IP address.

#### Step 10 Create the data folders.

Create the folders on RPi for the CPAP data: 

```
mkdir -p /home/rpi/cpapsrc/AirSense11-Data
```

Create the folders on home PC for the CPAP data:

```
mkdir -p /home/captain/cpapdst/AirSense11-Data
```

All user directories on Linux systems are in the /home directory. In step 4, when you used the RaspberryPi-Imager program, you created the user, rpi. Thus, rpi's home directory is: /home/rpi. The mkdir command with the -p switch creates two new nested directories, cpapsrc and another directory within cpapsrc called AirSense11-Data. Thus, the path to AirSense11-Data is: /home/rpi/cpapsrc/AirSense11-Data. Similarly for the directories on the home PC whose user account I identify as, captain.

#### Step 11 Download getdata_ezshare.sh

On your home PC, download the [getdata_ezshare.sh](https://github.com/murraydavis/SleepApnea_WifiUploads_Oscar-SleepHQ) file from my GitHub share. Modify its contents using a text editor such as vi. You need to make changes to reflect your folder path, username, WiFi network. Find and read the comment sections (lines preceded by ##). You could do this step on RPi, but I think you will find it faster if you do it on your own PC. Also, do not use a desktop app such as Libre Office (which embed app-specific characters in documents), use a simple text editing app. Make sure that you save the script as getdata_ezshare.sh and not getdata_ezshare.sh.txt. Of course, you can choose whatever name you like for the script, the part prior to .sh. Just remember that file names are case sensitive in Linux.

#### Step 12 Edit getdata_ezshare.sh to reflect your environment.

I removed some of jimbococo's comments. The comments that I added begin with a double number sign, ##. Read those comments carefully and make changes that reflect your home environment. Here are the lines that need to be changed to reflect your environment. 

1. line 15: sudo nmcli connection down mywifinetwork, change mywifinetwork

2. line 22: sudo nmcli connection up 'ez Share', no change needed unless you modify ezShare's default settings

3. line 29: mainDir="/home/rpi/cpapsrc/AirSense11-Data/", change if you used a different username and data path

4. line 53: whiteList=".log|.crc|.tgt|.dat|.edf|.EDF|.json|DATALOG|SETTINGS", add the .EDF file extension

5. line 262: sudo nmcli connection up mywifinetwork, change mywifinetwork

6. line 267: mv /home/rpi/cpapsrc/AirSense11-Data/STR.EDF /home/rpi/cpapsrc/AirSense11-Data/STR.edf -f, modify if you used a different username and datapath

7. line 272: sshpass -f /home/rpi/cpapsrc/scppassfile scp -r /home/rpi/cpapsrc/AirSense11-Data/* homePCuser@homePCIPAddress:/home/homePCuser/cpapdst/AirSense11-Data, change if you used different usernames and paths

#### Step 13 Copy getdata_ezshare.sh from home PC to RPi.

Upload/copy the modified getdata_ezshare.sh to RPi. You can copy in one of two ways: 1. From RPi or 2. From home PC  or 3. Using sneakernet and a USB stick

1. From RPi, use the scp command to copy the script from your home PC to RPi.

First, ssh into RPi using the rpi account: ssh rpi@ipaddressofRPi. For example, ssh rpi@192.168.1.20. Now, let's assume that on your home PC:

1.1 Your username is: captain

1.2 Your home WiFi network IP address is: 192.168.1.5

1.3 The directory that you created for working with cpap data is: /home/captain/cpapdst (dst=destination as a mnemonic). getdata_zshare.sh is inside this folder.

1.4 You want to put the getdata_ezshare.sh file in /home/rpi/cpapsrc on RPi. 

Issue this command from RPi, you will be prompted for captain's password: 

```
scp captain@192.168.1.5:/home/captain/cpapdst/getdata_ezshare.sh /home/rpi/cpapsrc
```

The syntax of the scp command is: scp remoteusername@remotePCIP:/sourcepath destinationpath, that is, scp source destination. Sometimes the source is the remote PC, sometimes it is the local PC; same for destination. We are copying a file from your home PC, which is the remote PC. Thus, we have to use your account on the home PC, captain; and your home PC IP address, 192.168.1.5. The destinationpath is the absolute path where you want getdata_ezshare.sh to be copied to on RPi. Note the space after sourcepath.


If you get a connection refused error, you may not have the openSSH daemon installed on your home PC; or the daemon may be installed, but it is simply not running. Try first to see if it is installed: 

```
# Two methods are shown to find out if openssh is installed. As you see, it is installed on my home PC.

[~]$ dnf list installed | grep openssh
openssh.x86_64                                    9.0p1-17.fc38                          @updates                                       
openssh-clients.x86_64                            9.0p1-17.fc38                          @updates                                       
openssh-server.x86_64                             9.0p1-17.fc38                          @updates  
                                     
[~]$ dnf repoquery openssh
Last metadata expiration check: 0:01:41 ago on Thu 30 Nov 2023 07:54:53 AM PST.
openssh-0:9.0p1-14.fc38.1.x86_64
openssh-0:9.0p1-17.fc38.x86_64

# If openssh is not installed, install it:

[~]$ sudo dnf install openssh
```

So, let's assume that openssh is installed, is it running?

```
sudo systemctl status sshd 
```

If the daemon is listed as inactive (dead), start it: 

```
sudo systemctl start sshd
```

If you issue the status command again, you will see the status as active (running). I do not keep the sshd daemon running on my system because of security concerns. I only enable it when needed. If you have no issues with sshd always running, enable it permanently with this command: 

```
sudo systemctl enable sshd
```

2. From your home PC, use the scp command to copy/push the script from your home PC to RPi. The IP address of RPi is: 192.168.1.20. As described above, on your home PC, your home folder for cpap data is: /home/captain/cpapdst. The scp command would be:

```
scp /home/captain/cpapdst/getdata_ezshare.sh rpi@192.168.1.20:/home/rpi/cpapsrc
```

3. Copy getdata_ezshare.sh using good old sneakernet. Copy the script onto a USB stick. Take the stick to RPi and insert the stick into one of the available USB ports and SSH into RPi from the home PC.

```
# The following commands are issued on my home PC that has a USB stick attached.

# You will learn about aliases. Aliases are any custom command, usually based on a built in command. I put my aliases in my .bashrc file.

# Here are two aliases that I use to get partition information. The format of the alias command inside the .bashrc file is slightly different because of punctuation.

# For example, the mylsblk alias inside .bashrc is: alias mylsblk='sudo lsblk | grep 'sd''

# The myfdisk alias is: alias myfdisk='sudo fdisk -l | grep '/dev/sd''

# Why am I using aliases for sudo fdisk -l and sudo lsblk? To find out issue these commands without the pipe to grep. 

[~]$ alias mylsblk
alias mylsblk='sudo lsblk | grep sd'

[~]$ alias myfdisk
alias myfdisk='sudo fdisk -l | grep /dev/sd'

# What are my disk partitions? Linux/Fedora conventions specify that the first hard disk will be disk sda. An external drive such as a USB drive will be sdb.

[~]$ myfdisk
Disk /dev/sda: 238.47 GiB, 256060514304 bytes, 500118192 sectors
/dev/sda1       2048    206847    204800   100M EFI System
/dev/sda2     206848    239615     32768    16M Microsoft reserved
/dev/sda3     239616 167923711 167684096    80G Microsoft basic data
/dev/sda4  498020352 500117503   2097152     1G Windows recovery environment
/dev/sda5  167923712 168026111    102400    50M EFI System
/dev/sda6  168026112 498020351 329994240 157.4G Linux filesystem
Disk /dev/sdb: 954 MiB, 1000341504 bytes, 1953792 sectors
/dev/sdb1  *       32 1953791 1953760  954M  c W95 FAT32 (LBA)

# We see that our USB drive is /dev/sdb1. However, we need its mount point in order to copy a file to the USB drive. We get that info from the lsblk command.

[~]$ mylsblk
sda      8:0    0 238.5G  0 disk 
├─sda1   8:1    0   100M  0 part 
├─sda2   8:2    0    16M  0 part 
├─sda3   8:3    0    80G  0 part 
├─sda4   8:4    0     1G  0 part 
├─sda5   8:5    0    50M  0 part /boot/efi
└─sda6   8:6    0 157.4G  0 part /var/lib/snapd/snap
sdb      8:16   1   954M  0 disk 
└─sdb1   8:17   1   954M  0 part /run/media/captain/2F6B-4C7D

# We see that sdb1 is mounted at: /run/media/captain/2F6B-4C7D. So, let's copy getdata.ezshare.sh to that mount point, i.e., to the USB drive.

[~]$ cp /home/captain/cpapdst/getdata.ezshare.sh /run/media/captain/2F6B-4C7D/

# We now safely eject the USB stick from our system using either a desktop file manager like Nemo. Just click on the symbol that looks like a hardware eject button.

# We can also safely eject the USB stick from the command line.

[~]$ sudo eject /dev/sdb1

FWIW, in Nemo, find the USB drive. If you hover the mouse over the drive name, the mount point listed above will appear.

```

Carry the USB stick to RPi and insert it into one of its free USB ports. Go back to your home computer and SSH into RPi.

```
[~]$ ssh rpi@191.168.1.20
Password:

pi@cpap:~ $ lsblk | grep sd
sda           8:0    1  954M  0 disk 
`-sda1        8:1    1  954M  0 part /media/rpi/2F6B-4C7D

# Note the difference between how the partitions are named in Debian (RPi) and the partition scheme on my home PC, Fedora.

# We now use the mount point info to copy our file to RPi.

rpi@cpap:~ $ cp /media/rpi/2F6B-4C7D/getdata_ezshare.sh /home/rpi/cpapsrc/

rpi@cpap:~ $ ls /home/rpi/cpapsrc 
AirSense11-Data  scppassfile getdata_ezshare.sh
```

#### Step 14 Make getdata_ezshare.sh an executable file.

A file with an .sh extension is a shell script, an executable file. We have to tell the operating system that it is an executable file. We do this by adding the executable flag (x) to the file. Issue this command: 

```
# Prior to making the changes to the file, here is how the permissions looked.
# First cd (change directory) to the cpapsrc directory and get a detailed listing of the permissions/flags on getdata_ezshare.sh.

rpi@cpap:~ $ cd cpapsrc

rpi@cpap:~/cpapsrc $ ls -l getdata_ezshare.sh

-rw-r--r-- 1 rpi rpi 7069 Nov 26 06:35 getdata_ezshare.sh

# Add the executable flag using the chmod command.

rpi@cpap:~/cpapsrc $ chmod +x getdata_ezshare.sh

# The permission flags after the change show that the letter x has been added.

rpi@cpap:~/cpapsrc $ ls -l getdata_ezshare.sh
-rwxr-xr-x 1 rpi rpi 7069 Nov 26 06:35 getdata_ezshare.sh

# Permissions are written in triplets, read, write, execute for three entities: owner (u), group (g), others/world/everyone (o).

# On a server system, you would not use the chmod +x command because that command would give execute permission to everyone.

# Instead, you would issue this command:

rpi@cpap:~/cpapsrc $ chmod u+x getdata_ezshare.sh

# Here are the new permissions if you started with chmod u+x:

rpi@cpap:~/cpapsrc $ ls -l getdata_ezshare.sh 
-rwxrw-r--. 1 rpi rpi 0 Nov 27 15:39 getdata_ezshare.sh

```

#### Step 15. How to run or execute the script on RPi.

Now that you have edited the script to reflect your settings and made the file executable, you are now ready to run the script to get the data from the ezShare SD card. At a command prompt, issue the following command, if you are in the /home/rpi/cpapsrc directory where getdata_ezshare.sh is located:

```
# The script can also be run with this command: bash getdata_ezshare.sh

rpi@cpap:~/cpapsrc $ ./getdata_ezshare.sh

# After a pause, you will see output similar to the following:

Connection 'contortionist' successfully deactivated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/109)
Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/110)
Scan of dir=A:
Scan of dir=A:DATALOG
Scan of dir=A:DATALOG/20231113
Scan of dir=A:DATALOG/20231114
Scan of dir=A:DATALOG/20231115
Scan of dir=A:DATALOG/20231116
.
.
.
Updated file added to downloads: DATALOG/20231126/20231127_023141_PLD.edf
Updated file added to downloads: DATALOG/20231126/20231127_023141_SA2.edf
Updated file added to downloads: DATALOG/20231126/20231127_023141_BRP.edf
Updated file added to downloads: DATALOG/20231126/20231127_044930_CSL.edf
Updated file added to downloads: DATALOG/20231126/20231127_044930_EVE.edf
Updated file added to downloads: DATALOG/20231126/20231127_044934_PLD.edf
Updated file added to downloads: DATALOG/20231126/20231127_044934_SA2.edf
Updated file added to downloads: DATALOG/20231126/20231127_044934_BRP.edf
Scan of dir=A:SETTINGS
Updated file added to downloads: STR.EDF
330 File(s) scanned in 16 Folder(s)
Downloading of 45 Files in progress, Please Wait...
26 New(s) file(s) downloaded
19 File(s) Updated
Completed in 13 seconds
Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/111)
```

If you are not in the cpapsrc directory, provide the full path to the script:

```
/home/rpi/cpapsrc/getdata_ezshare.sh
```

Better yet, create a directory for your scripts, add that directory path to the $PATH variable in your .bashrc file so that all scripts are available from anywhere. Reload .bashrc using the source command to re-read .bashrc so the changes are available immediately. There is no need to logoff and on. Fedora uses the .bashrc file as a configuration file for the Bash Shell environment. The >> in the third command says to append the content of the echo statement (everything inside the single quotes) to .bashrc. If you used a single >, you would overwrite the entire file.

```
# Start in the home directory.

rpi@cpap:~ $ mkdir scripts
rpi@cpap:~ $ mv /home/rpi/cpaprsc/getdata_ezshare.sh /home/rpi/scripts
rpi@cpap:~ $ echo 'export PATH="/home/rpi/scripts:$PATH"' >> /home/rpi/.bashrc
rpi@cpap:~ $ source ~/.bashrc
```

Now, you can run getdata_ezshare.sh from any working directory.

Are your curious what the directory on the ezShare SD card looks like? Open a web browser other than Firefox and type this URL: http://192.168.4.1/dir?dir=A:

```
http://192.168.4.1/dir?dir=A:

2016-11-12   21:36:36           0KB   ezshare.cfg
   2023-11-13   23:35: 0          16KB   JOURNAL.JNL
   2023-11-13   23:35: 0         <DIR>    DATALOG
   2023-11-13   23:35: 0         <DIR>    SETTINGS
   2023-11-13   23:35:16           1KB   Identification.crc
   2023-11-13   23:35:16           1KB   Identification.json
   2023-11-26    5:16:24         106KB   STR.EDF

Total Entries: 7
Total Size: 124KB
```

#### Step 16 How to get ResMed data to SleepHQ. Option 1. Copy the data from RPi to Home PC and drag and drop to SleepHQ from there.

I prefer this method because I think it is faster than using VNC to connect to RPi. I find working at the RPi desktop via VNC to be slow because a base RPi PC simply does not have enough resources to create a speedy desktop environment. I want to do the drag and drop of the data files from my home PC to the SleepHQ website.

1. Step 1. On RPi, copy the data to home PC.

The working cpap directory on RPi is cpapsrc (src=source as a mnemomic) and the cpap working directory on your home PC is cpapdst. The following command is issued on RPi. You are copying the data already generated on RPi from RPi to your home PC. The scp command overwrites any existing data. You are prompted for the password for the captain account.

```
rpi@cpap:~ $ scp -r /home/rpi/cpapsrc/AirSense11-Data/* captain@192.168.1.5:/home/captain/cpapdst/AirSense11-Data
captain's@192.168.1.5's password: 

# There is a large data display as the files are copied, but I am not showing that.
```

The format of the command is: scp (secure copy) -r (recursive, drill down through sub-directories) PathOnLocalPC/*(get everything) AccountOnRemotePC@RemotePCIPaddress:/PathToDataOnRemotePC. Note the space after *. I use absolute paths which is recommended because prior to starting the copy you may be working in some other directory and relative paths would fail.

Suppose you do not want to type captain's password each time after you run this command.

You need to install the package sshpass on RPi.

```
rpi@cpap:~ $ sudo apt install sshpass

# The command then becomes...note the space after the *.

rpi@cpap:~ $ sshpass -p captainpassword scp -r /home/rpi/cpapsrc/AirSense11-Data/* captain@192.168.1.5:/home/captain/cpapdst/AirSense11-Data

# There is a bit of a security risk in using this command because now the captain password shows up in the history command. History is the command to list past commands. A better alternative is to create a password file with only one line, the captain password.

# Where am I now?

rpi@cpap:~ $ pwd
/home/rpi/cpapsrc

# Create the password file using the echo command, with its content, the password.

rpi@cpap:~ $ echo 'captainpassword'>scppassfile

# Now, use the sshpass command, pointing to the password file.

rpi@cpap:~ $ sshpass -f /home/rpi/cpapsrc/scppassfile scp -r /home/rpi/cpapsrc/AirSense11-Data/* captain@192.168.1.5:/home/captain/cpapdst/AirSense11-Data

# An interesting note, the output that typically appears with the scp command is now supressed. After a pause, you are simply returned to the command prompt.
# sshpass is a great tool. You no longer have to remember passwords after you create the password file.

```

And, of course, you can create a simple script file inside the /home/rpi/scripts folder that contains just the above sshpass command. Call it something easy such as mycopy.sh. Or, create an alias inside .bashrc.

2. Step 2. Add the sshpass command to getdata_ezshare.sh.

Go to the end of the getdata_ezshare.sh file, line 272. Modify the command for your setting. When you run getdata_ezshare.sh, it first downloads the data from the ezShare SD card to RPi and then copies the data to the home PC.

3. Step 2 Drag and drop files to SleepHQ.

Now that you have last night's data on your home PC, open a file explorer application such as Nemo, drag and drop the files/folders to the SleepHQ site using the Data Import menu. An interesting note about the Data Import window. On the right-hand side, the files that are needed are listed: STR.edf, Indentification.crc, Identification.json; as well as the folders: DATALOG and SETTTIGS. These file and folder names are case sensitive. If SleepHQ detects that any of these items are missing, you will see the missing files highlighted in red.

#### Step 17  How to get ResMed data to SleepHQ. Option 2. Use VNC to connect to RPi and drag and drop from there.

1. Instead of using the command line, we are going to use a desktop VNC application such as TigerVNC Viewer. Open VNC and type in the home WiFi network IP of RPi. You will be prompted for rpi's password. You now have a desktop view on RPi.

2. The default taskbar on a RaspberryPi PC is typically across the top. Open the File Manager (the folders icon) and navigate to your cpap folder: /home/rpi/cpapdst/AirSense11-Data and select all the files with CTRL-A. Open the web browser (the blue globe),navigate to the SleepHQ site, logon, and go to the data imports menu. Simply drag and drop your files and click the Begin Upload button.

A word of warning. Depending on the RPi model that you choose, the desktop environment and desktop applications like the web browser may be very slow to open and use.

#### Step 18 How to get ResMed data to SleepHQ. Option 3. Run all commands from your home PC...no need to ssh into RPi to run the getdata_ezshare.sh script.

One can easily run commands on a remote system. We want to execute getdata_ezshare.sh every morning. Let's run that command from the home PC instead of from RPi. These commands are run on your home PC.

```
# Eliminate the need of using ssh to connect to RPi in order to run getdata_ezshare.sh. pwd=print working directory

$ pwd
/home/captain/cpapdst

# Create a password file that contains the rpi password.

$ echo 'rpipassword' > rpipass
$ cat rpipass
rpipassword

$ sshpass -f /home/captain/cpapdst/rpipass ssh rpi@192.168.1.20 /home/rpi/cpapsrc/getdata\_ezshare.sh
```

The cursor at the command prompt disappears for a short while and then the output that would normally appear on RPi is displayed on your home PC, output similar to that from Step 15. You then can drag and drop the files from the AirSense11-Data folder to the SleepHQ site. 

As an aside, you can execute any command, even built in commands using this method.

```
# get uptime, the amount of time since last boot, on RPi

$ sshpass -f /home/captain/cpapdst/rpipass ssh rpi@192.168.1.20 'uptime'
 12:20:40 up 19 days, 22:35,  3 users,  load average: 0.01, 0.03, 0.00
```

 You can even run a local script that resides on your home PC on the remote system. Here's an example:

```
$ pwd
$ /home/captain/cpapdst
$ echo 'pwd' > mylocalscript.sh
$ cat mylocalscript.sh 
pwd
$ chmod +x mylocalscript.sh 

$ sshpass -f /home/captain/cpapdst/rpipass ssh rpi@192.168.1.20 'bash -s' < /home/captain/cpapdst/mylocalscript.sh
/home/rpi

# Note the output, /home/rpi. This tells you that the local script mylocalscript.sh was run on RPi and not on the home PC.
```

I leave a challenge for my readers. Suppose we first copy getdata_ezshare.sh from RPi to home PC. If getdata_ezshare.sh was in the folder /home/captain/cpapdst would the following command run successfully?

```
$ sshpass -f /home/captain/cpapdst/rpipass ssh rpi@192.168.1.20 'bash -s' < /home/captain/cpapdst/getdata_ezshare.sh
```

### Future tasks, unfinished business.

1. Figure out an API solution to get data to SleepHQ. There must be a way to create a script to upload the data from the cpapdst folder on the home PC to SleepHQ using your SleepHQ username and password. No more drag and drop.

2. Figure out why the getdata_ezshare.sh script downloads STR.EDF and not STR.edf.

3. Over time, the number of files on the ezShare SD card continue to build up. Devise a solution to periodically purge the data without sneakernet and without formatting the SD card.

4. Get a USB WiFi dongle and dual-home RPi, built-in WiFi on home network, USB WiFi dongle on ezShare hotspot dongle. This would help with dropped connections if RPi gets hung on the ezShare network. This is defined as a dual-homed system.

5. Experiment with changing the ezShare WiFi channel. Maybe the poor performance within our suite is caused by overcrowding on channel 11.

6. Create a scheduling script to run getdata_ezshare.sh at the same time each day. Then the only task is to drag and drop the files to SleepHQ.

7. Even better incorporate the API solution for the scheduled script. A no touch solution.

8. Find a solution for password less SSH keys bypassing the need for SSH passwords. Maybe using ssh-agent, etc.

