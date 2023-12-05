#!/bin/bash

##
## My comments begin with a double number sign, Jimbo's commaents begin with a single number sign or multiple number signs.
##

##
## Thank you to https://github.com/jimbocococo/EzShare-SdcardWifi-Downloader
## This script is a modification of Jimbo's EzShareWifiSDcardDownloader.sh script.
##

## 
## Disconnect from your home wifi network, my SSID is mywifinetwork. SSIDs are case-sensitive.
##
sudo nmcli connection down mywifinetwork
##
## Connect to the ezShare network whose SSID is: ez share
##
## I think the original SSID is: ez share, all lower case with a space between the z and s. The connection command would be as follows:
## Note: single quotes, not double quotes around the SSID.
##
sudo nmcli connection up 'ez Share'
##
## Specify the path of the local directory on RPi for the data.
## This is the absolute, full path to the folder.
## The sudo user, the main account automatically created on the Raspberrypi is: rpi
## rpi's home directory is /home/rpi, modify the next line to reflect your paths.
##
mainDir="/home/rpi/cpapsrc/AirSense11-Data/"

# Ez Share top Url, top directory, first folder and subfolders
mainUrl="http://192.168.4.1"
remoteDir=("dir=A:")

# auto check if all utilities are present
check="true"

# 3 Modes of download: 
# normal
# soft
# hard
# soft download mode is slower, dl 1 by 1 but safer (useless but was my first method so if problem use it)
# hardmode is fast but less safe (if card crash disable it)
mode="normal"

# parallels download aviable only for normal mode (decrease if computer isssue or play with it to try to download faster)
pDl=16 #default: 8

##
## I added the .EDF file ending to the whitelist.
##
# Use this program as a blacklist or a whitelist, as you prefer
whiteList=".log|.crc|.tgt|.dat|.edf|.EDF|.json|DATALOG|SETTINGS"
#blackList=".Spotlight-V100|.Trashes|._.DS_Store|.DS_Store|.fseventsd|Volume|SYSTEM~1|EZSHARE.CFG|Id.txt"                                         
                                                                                                      
########### Don't touch the rest ########### ########### ########### ########### ########### ########### ###########



########### some variables ###########
SECONDS=0

currentDir=0
nbdAll=0

nbfAll=0
nbfNew=0
nbfUpd=0

nbfDl=0
dlList=()


########### check installed utilities ###########
for ex in \
echo echo date grep sed xargs wget
  do
    loc=$(which "${ex}")
    if [ "${loc}" = "" ] ; then
      echo "${ex} is missing"
      check="false"
    fi
done
if [ "${check}" = "false" ] ; then
    echo "Some utilities are missing"
    exit 1
fi
ECHO=$(which echo)


#################### download files ####################
# from absolute link could be faster with the download links
# from the webbrowser but I started like that
dlList()
{
  [ -d "${mainDir}$/{relPath[$currentDir]}" ] || mkdir -p "${mainDir}/${relPath[$currentDir]}"
  if [ "${mode}" == "normal" ]; then
    dlList["$nbfDl"]="${localFile} ${mainUrl}/${relFile}"
    let nbfDl=nbfDl+1
  else
    echo "${localFile} ${mainUrl}/${relFile}" |  xargs -n 2 -P "${pDl}" wget --no-use-server-timestamps -q -O 
  fi
}


#################### show files to downlad ####################
dlShow()
{
  for value in "${dlList[@]}"
  do
    echo "${value}"
  done
}


#################### dowlnoad files ####################
dlProcess()
{
   echo "${dlList[*]}" | xargs -n 2 -P "${pDl}" wget --no-use-server-timestamps -q -O 
}


########## cleanning lines ##########
getLine()
{
  wget -q -O- "${mainUrl}/dir?${remoteDir[$currentDir]}" |
  sed -n '/a>$/p' | sed -e '/\.<\/a>$/d' |  sed -e 's/<\/a>//g' | sed -e 's/<a href="//g' | sed -e 's/">//g' |
  sed -e's/- /-0/g' | sed -e 's/: /:0/g' | sed -e 's/&lt;DIR&gt;/DIR/g' |
  if [ ! -z "$blackList" ] ; then grep -vwE -i "${blackList}" ; elif [ ! -z "$whiteList" ] ; then grep -E -i "${whiteList}" ; fi
}


#################### get info from the webbrowser ####################
getDataInfo()
{ 
  while read line ; do
    if [ ! -z "$line" ]; then
      arr=(${line})
      for i in "${arr[@]}" ; do
        echo $i
      done
    fi
  done <<< $(getLine)
}


#################### scan server ####################
fileORdir()
{
echo "Scan of ${remoteDir[0]}${relPath[$currentDir]}"
while read fileDate ; do
  if [ ! -z "$fileDate" ]; then
  read fileTime
  read fileSize
  read link
  read fileName
  remoteTime="$(date -d "${fileDate} ${fileTime}" +%s)"
  ########## DIR ##########
  if [ "$fileSize" = "DIR" ] ; then
    let nbdAll=nbdAll+1
    let currentDir=currentDir+1
    #chemin relatif du dossier (local&web) + #chemin relatif du champ de dossier web
    if [ "$currentDir" -eq "1" ] ; then
      relPath[$currentDir]="${fileName}"
      remoteDir[$currentDir]="${remoteDir[0]}${fileName}"
    else
      relPath[$currentDir]="${relPath[$currentDir-1]}/${fileName}"
      remoteDir[$currentDir]="${remoteDir[$currentDir-1]}%5C${fileName}"
    fi
    fileORdir
    let currentDir=currentDir-1
########## To check >>>> (maybe can't work if server return the bad informations could be usefull to skip folders have to add it)
: <<'END'
    local_DIR="${mainDir}/${relPath[$currentDir]}"

    if ! [ -d "${local_DIR}" ]; then
      let nbdNEW=nbdNEW+1
      fileORdir
      echo "New directory find: ${local_DIR}"
    elif [ "$(date -r "${local_DIR}" +%s)" -lt "$(date -d "${fileDate}" +%s)" ] ; then
      let nbdUPD=nbdUPD+1
      fileORdir
      echo "Updated directory find: /${local_DIR}"
    fi
END
########## <<<<< To check 
  ########## FILE ##########
  else
    let nbfAll=nbfAll+1

    if [ "$currentDir" -eq "0" ] ; then
      relFile="${fileName}"
    else
      relFile="${relPath[$currentDir]}/${fileName}"
    fi

    localFile="${mainDir}/${relFile}"
    if ! [ -f "${localFile}" ]; then
      let nbfNew=nbfNew+1
      if [ "${mode}" == "soft" ] ; then
        dlList
        echo "New file downloaded: ${relFile}"
      elif  [ "${mode}" == "normal" ] ; then
        dlList
        echo "Updated file added to downloads: ${relFile}"  
      else
        dlList &
        echo "New file added to downloads: ${relFile}"
      fi
    elif [ "$(date -r "${localFile}" +%s)" -lt "${remoteTime}" ] ; then
      let nbfUpd=nbfUpd+1
      if [ "${mode}" == "soft" ] ; then
        dlList
        echo "File updated: ${relFile}"
      elif  [ "${mode}" == "normal" ] ; then
        dlList
        echo "Updated file added to downloads: ${relFile}"        
      else
        dlList &
        echo "Updated file added to downloads: ${relFile}"

      fi
    fi
  fi
fi

done <<< $(getDataInfo)
}

########## main body ##########
#2021-3-24 13:45:10

fileORdir

echo "${nbfAll} File(s) scanned in ${nbdAll} Folder(s)"

if [ "${mode}" == "normal" ] && [ "${nbfDl}" -ne "0" ] ; then
  echo "Downloading of ${nbfDl} Files in progress, Please Wait..."
  dlProcess 
fi 

if [ "${nbfNew}" != "0" ] ; then echo "${nbfNew} New(s) file(s) downloaded" ; fi

if [ "${nbfUpd}" != "0" ] ; then echo "${nbfUpd} File(s) Updated" ; fi


if (( $SECONDS > 3600 )) ; then
    let "hours=SECONDS/3600"
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "Completed in $hours hour(s), $minutes minute(s) and $seconds second(s)" 
elif (( $SECONDS > 60 )) ; then
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "Completed in $minutes minute(s) and $seconds second(s)"
else
    echo "Completed in $SECONDS seconds"
fi
##
## Reconnect to home wifi.
##
sudo nmcli connection up mywifinetwork

## 
## Rename STR.EDF to the correct filename STR.edf.
##
mv /home/rpi/cpapsrc/AirSense11-Data/STR.EDF /home/rpi/cpapsrc/AirSense11-Data/STR.edf -f
##
## Optional, run the sshpass command. You need to create the scppassfile and install sshpass first.
## You need to change homePCuser and homePCIPAddress to reflect your environment...as well as the paths, if you chose different paths and rpi if you chose a different username for RPi
## 
sshpass -f /home/rpi/cpapsrc/scppassfile scp -r /home/rpi/cpapsrc/AirSense11-Data/* homePCuser@homePCIPAddress:/home/homePCuser/cpapdst/AirSense11-Data

