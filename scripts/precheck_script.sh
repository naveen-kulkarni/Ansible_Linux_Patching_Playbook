#!/bin/bash

SERVER=`uname -n|awk -F "." '{print $1}'`
DT=`date +%Y%m%d`

req=$1

if [[ -n "$req" ]]; then
    mkdir -p /var/tmp/"$req"_"$SERVER"_"$DT"

OUTPUTFOLDER="/var/tmp/"$req"_"$SERVER"_"$DT""
OUTPUTFILE="/var/tmp/"$req"_"$SERVER"_"$DT"/"$SERVER"_Precheck_"$DT".txt"
DEST=/net/share-02/prd_nfs_itops_unixadmin_01/team_folders/ansible_backup

#ROOT CHECK
clear
ID=`id | sed 's/uid=\([0-9]*\)(.*/\1/'`
if [ "$ID" != "0" ] ; then
        echo "You must be root to execute the script $0."
        exit 1
fi

#HOST INFORMATION
linuxhost() {
echo ""
echo "HOST INFORMATION"
echo "----------------"
echo ""
uname -a
cat /etc/redhat-release
echo ""
echo "UPTIME & USER INFO"
echo "------------------"
echo ""
/usr/bin/uptime
who
echo ""
}

#Disk Information
linuxdisk() {
echo ""
echo "Filesystem Information"
echo "----------------------"
echo ""
fdisk -l 2>/dev/null
echo ""
echo "FILE SYSTEMS: "
echo "------------"
echo ""
df -h 2>1
echo ""
echo "FSTAB DETAILS:"
echo "--------------"
echo ""
cat /etc/fstab
echo ""
echo "MOUNT DETAILS:"
echo "--------------"
echo ""
mount
echo ""
echo "IOSTAT DETAILS:"
echo "---------------"
echo ""
iostat
echo ""
}

#HArdware Information
linuxhardware() {
echo ""
echo "Hardware Information"
echo "---------------------"
echo ""
echo "NUMBER OF CPU's:"
echo "----------------"
echo ""
cat /proc/cpuinfo | egrep "processor|model name"
echo ""
echo "MEMORY INFORMATION:"
echo "-------------------"
echo ""
cat /proc/meminfo
echo ""
}

#NETWORK INFORMATION
linuxnetwork() {
echo ""
echo "NETWORK INFORMATIONS"
echo "--------------------"
echo ""
echo "IFCONFIG INFO"
echo "-------------"
echo ""
ifconfig -a
echo ""
echo "NIC FDX/HDX - SPEED"
echo "-------------------"
echo ""
ETH=`/sbin/ifconfig -a | grep Link | grep HWaddr |awk  '{print $1}'`
for EN in $ETH
do
/sbin/ethtool $EN
done
echo ""
echo "ROUTES DETAILS:"
echo "--------------"
echo ""
netstat -rn
echo ""
echo "NETSTAT -IN"
echo "------------"
echo ""
netstat -in
echo ""
echo "cat /etc/hosts "
echo "----------------"
cat /etc/hosts |sed -e '/^#/d'
echo ""
echo "cat /etc/resolv.conf"
echo "--------------------"
cat /etc/resolv.conf |grep -v search | sed -e '/^#/d'
echo ""
}

#Service List
linuxservice()
{
echo ""
echo "Chkconfig list"
echo "---------------"
echo ""
/sbin/chkconfig --list 2>/dev/null
echo ""
echo "Error Logs"
echo "-----------"
echo ""
grep -i FATAL /var/log/messages | cut -d' ' -f6- | sed -e "s/[0-9]/0/g" | sort | uniq
grep -i ERROR /var/log/messages | cut -d' ' -f6- | sed -e "s/[0-9]/0/g" | sort | uniq
echo ""
echo "Dmesg Logs"
echo "----------"
echo ""
dmesg | grep -i fail | sed -e "s/[0-9]/0/g" | sort | uniq
dmesg | grep -i error | sed -e "s/[0-9]/0/g" | sort | uniq
}

#Copy Configuration files
linuxconfigs()
{
cp -p /etc/passwd $OUTPUTFOLDER
cp -p /etc/shadow $OUTPUTFOLDER
cp -p /etc/group $OUTPUTFOLDER
cp -p /etc/sudoers.d/* $OUTPUTFOLDER
cp -p /etc/*.conf $OUTPUTFOLDER
}

# Compress backup and copied to Centralized location
linuxcompress()
{
/bin/tar -cf $OUTPUTFOLDER.tar $OUTPUTFOLDER
sudo cp -r $OUTPUTFOLDER.tar $DEST
}


#Solaris Functions

#HOST INFORMATION
solarishost() {
echo ""
echo "HOST INFORMATION"
echo "----------------"
echo ""
uname -a
echo ""
echo "UPTIME & USER INFO"
echo "------------------"
echo ""
/usr/bin/uptime
who
echo ""
}

#Disk Information
solarisdisk() {
echo "Device Information"
echo "-------------------"
echo|format 2>/dev/null
echo ""
echo "IOSTAT DETAILS:"
echo "--------------\n"
iostat -Een
echo ""
echo "FILE SYSTEMS: "
echo "-------------\n"
df -k 2>1
echo ""
echo "VFSTAB DETAILS:"
echo "---------------\n"
cat /etc/vfstab
echo ""
echo "MOUNT DETAILS:"
echo "---------------\n"
mount -p
echo "\n"
VFS=`cat /etc/vfstab | sed -e '/^#/d' | awk '{print $3}' | sed -e '/dev\/fd/d' -e '/-/d' -e '/proc$/d'`
echo "\nNumber of mounts listed in vfstab (minus proc and /dev/fs)"
df -k $VFS | sed -e '/^Filesystem/d' | wc -l
echo "\nNumber of mounts currently mounted (minus proc and /dev/fs)"
df -k | sed -e '/^Filesystem/d' -e '/proc/d' -e '/dev\/fd/d' | wc -l
echo "\n"
}

#Solaris hardware
#
solarishardware() {
echo "hardware Information"
echo "--------------------"
echo ""
echo "NUMBER OF CPU's:"
echo "---------------\n"
psrinfo -p
echo ""
psrinfo -p -v
echo ""
echo "PRTDIAG DETAILS:"
echo "-----------------"
/usr/platform/`uname -m`/sbin/prtdiag -v
echo "\n"
echo ""
echo "EEPROM DETAILS:"
echo "----------------"
eeprom
}

#Network Information
solarisnetwork() {
echo "NETWORK INFORMATION"
echo "-------------------"
echo ""
echo "IFCONFIG INFO"
echo "-------------"
ifconfig -a
echo ""
echo "dladm show-dev"
echo "--------------"
dladm show-dev
echo ""
echo "dladm show-link"
echo "---------------"
dladm show-link
echo ""
echo "Routing Information"
echo "-------------------"
netstat -nr
echo ""
}
###Service
solarisservice()
{
echo "LISTING INETD.CONF"
echo "------------------"
echo ""
cat /etc/inet/inetd.conf | grep -v "#"
echo "LISTING ERRORS [IF/ANY]"
echo "-----------------------"
echo ""
grep -i FATAL /var/adm/messages | cut -d' ' -f6- | sed -e "s/[0-9]/0/g" | sort | uniq
grep -i ERROR /var/adm/messages | cut -d' ' -f6- | sed -e "s/[0-9]/0/g" | sort | uniq
echo ""
echo "ONLINE Services"
echo "----------------"
svcs -a | grep -i online
echo ""
echo "OFFLINE Services"
echo "-----------------"
svcs -a | grep -i offline
echo ""
echo "DISABLED services"
echo "------------------"
svcs -a | grep -i disabled
echo "Maintanence Services"
echo "--------------------"
svcs -a | grep -i maintenance
echo ""
}

#Copy Configuration files
solarisconfigs()
{
cp -p /etc/passwd $OUTPUTFOLDER
cp -p /etc/shadow $OUTPUTFOLDER
cp -p /etc/group $OUTPUTFOLDER
cp -p /etc/sudoers.d/* $OUTPUTFOLDER
cp -p /etc/*.conf $OUTPUTFOLDER
}

# Compress backup and copied to Centralized location
solariscompress()
{
/bin/tar -cf $OUTPUTFOLDER.tar $OUTPUTFOLDER
sudo cp -r $OUTPUTFOLDER.tar $DEST
}

#AIX
aixhost() {
echo ""
echo "HOST INFORMATION"
echo "----------------"
echo ""
uname -a
echo ""
oslevel -r
echo ""
echo "UPTIME & USER INFO"
echo "------------------"
echo ""
/usr/bin/uptime
who
echo ""
}

#Disk Information
aixdisk() {
echo ""
echo "Filesystem Information"
echo "----------------------"
echo ""
lsdev -Cc disk 2>/dev/null
echo ""
echo "FILE SYSTEMS: "
echo "------------"
echo ""
df -k 2>1
echo ""
echo "FSTAB DETAILS:"
echo "--------------"
echo ""
cat /etc/filesystems
echo ""
echo "MOUNT DETAILS:"
echo "--------------"
echo ""
mount
echo ""
echo "IOSTAT DETAILS:"
echo "---------------"
echo ""
iostat
echo ""
echo "LIST Disk DETAILS:"
echo "------------------"
echo ""
for HOST in $(lsvg); do lsvg -l $HOST ; done
echo ""
echo "LIST ALL ACTIVE VG's"
echo "---------------------"
echo ""
for HOST in $(lsvg -o); do lsvg -l $HOST ; done
echo ""
echo "" ; echo ""
lscfg -vpl hdisk*
echo ""
}

#HArdware Information
aixhardware() {
echo ""
echo "Hardware Information"
echo "---------------------"
echo ""
echo "NUMBER OF CPU's:"
echo "----------------"
echo ""
prtconf |grep -i processor
echo ""
echo "MEMORY INFORMATION:"
echo "-------------------"
echo ""
prtconf -m
echo ""
echo ""
prtconf |grep -i memory
echo ""
lsattr -El sys0 -a realmem
echo ""
bootinfo -r
echo "HARDWARE INFORMATION:"
echo "----------------------"
echo ""
lscfg -v
echo ""
}

#NETWORK INFORMATION
aixnetwork() {
echo ""
echo "NETWORK INFORMATIONS"
echo "--------------------"
echo ""
echo ""
ifconfig -a
echo ""
echo ""
lsdev -Cc if
echo ""
echo "-------------------------"
echo ""
echo "ROUTES DETAILS:"
echo "--------------"
echo ""
netstat -rn
echo ""
echo "NETSTAT -S"
echo "------------"
echo ""
netstat -s
echo ""
echo "cat /etc/hosts "
echo "----------------"
cat /etc/hosts |sed -e '/^#/d'
echo ""
echo "cat /etc/resolv.conf"
echo "--------------------"
cat /etc/resolv.conf |grep -v search | sed -e '/^#/d'
echo ""
}

#Service List
aixservice()
{
echo ""
echo "SERVICE list"
echo "-------------"
echo ""
lssrc -a
echo "INSTALLED PACKAGES"
echo "------------------"
instfix -ia
echo ""
echo "Error Logs"
echo "-----------"
echo ""
echo "BOOT LOGS"
echo "---------"
alog -o -t boot
echo ""
grep -i FATAL /var/adm/ras | cut -d' ' -f6- | sed -e "s/[0-9]/0/g" | sort | uniq
grep -i ERROR /var/adm/ras | cut -d' ' -f6- | sed -e "s/[0-9]/0/g" | sort | uniq
echo ""
echo "Dmesg Logs"
echo "----------"
echo ""
errpt -a
}

#Copy Configuration files
aixconfigs()
{
cp -p /etc/passwd $OUTPUTFOLDER
#cp -p /etc/shadow $OUTPUTFOLDER
cp -p /etc/group $OUTPUTFOLDER
cp -p /etc/sudoers.d/* $OUTPUTFOLDER
cp -p /etc/*.conf $OUTPUTFOLDER
}

# Compress backup and copied to Centralized location
aixcompress()
{
/bin/tar -cf $OUTPUTFOLDER.tar $OUTPUTFOLDER
sudo cp -r $OUTPUTFOLDER.tar $DEST
}

###PLATFORM INFORMATION###
case `uname` in
Linux)
echo "Generating system stats please wait (can take a few minutes on slow systems)"
echo ""
echo "File generated on `date`" > $OUTPUTFILE
echo "Host  Information . . . . . 10%"
linuxhost >> $OUTPUTFILE
echo "Disk  Information . . . . . 20%"
linuxdisk >> $OUTPUTFILE
echo "Hardware Information . . . . . 30%"
linuxhardware >> $OUTPUTFILE
echo "Network  Information . . . . . 50%"
linuxnetwork >> $OUTPUTFILE
echo "Service  Information . . . . . 75%"
linuxservice >> $OUTPUTFILE
echo "Copying Configuration . . . . . 97%"
linuxconfigs >> $OUTPUTFILE
echo "tar and scp Configuration file . . . . . 99%"
linuxcompress >> $OUTPUTFILE
echo ""
echo "File generated at $OUTPUTFILE on `date`"
exit
;;
SunOS)
echo "Generating system stats please wait (can take a few minutes on slow systems)"
echo ""
echo "File generated on `date`" > $OUTPUTFILE
echo "Host  Information . . . . . 10%"
solarishost >> $OUTPUTFILE
echo "Disk  Information . . . . . 20%"
solarisdisk >> $OUTPUTFILE
echo "Hardware Information . . . . . 30%"
solarishardware >> $OUTPUTFILE
echo "Network  Information . . . . . 50%"
solarisnetwork >> $OUTPUTFILE
echo "Service  Information . . . . . 75%"
solarisservice >> $OUTPUTFILE
echo "Copying Configuration . . . . . 97%"
solarisconfigs >> $OUTPUTFILE
echo "tar and scp Configuration file . . . . . 99%"
solariscompress >> $OUTPUTFILE
echo ""
echo "File generated at $OUTPUTFILE on `date`"
exit
;;
AIX)
echo "Generating system stats please wait (can take a few minutes on slow systems)"
echo ""
echo "File generated on `date`" > $OUTPUTFILE
echo "Host  Information . . . . . 10%"
aixhost >> $OUTPUTFILE
echo "Disk  Information . . . . . 20%"
aixdisk >> $OUTPUTFILE
echo "Hardware Information . . . . . 30%"
aixhardware >> $OUTPUTFILE
echo "Network  Information . . . . . 50%"
aixnetwork >> $OUTPUTFILE
echo "Service  Information . . . . . 75%"
aixservice >> $OUTPUTFILE
echo "Copying Configuration . . . . . 97%"
aixconfigs >> $OUTPUTFILE
echo "tar and scp Configuration file . . . . . 99%"
aixcompress >> $OUTPUTFILE
echo ""
echo "File generated at $OUTPUTFILE on `date`"
exit
;;
*)
exit 1
esac

else
    echo "argument error: Usage is Script.sh request number"
fi
