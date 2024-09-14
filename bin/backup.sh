#!/bin/bash

######################################################
#                                                    #
#              Written by Jacob Fakult               #
#                    12/17/2022                      #
#                                                    #
#  This script creates incremental backups of        #
#  Pre-selected target folders.                      #
#                                                    #
#  It behaves much like Apple's Time Machine.        #
#                                                    #
#  Each backup is saved in a folder named with its   #
#  Respective date.                                  #
#                                                    #
#  The latest backup is symlinked to ./last          #
#                                                    #
#  Unmodified files are hardlinked to the newer      #
#  Snapshots to remove duplicate data                #
#                                                    #
#  Deleted files will be removed from the latest     #
#  Snapshot, but will remain in previous snapshots.  #
#                                                    #
######################################################

# A bunch of this script has been modified for remote data backups

#######################################################
###  FEEL FREE TO CHANGE THESE LINES OF THE SCRIPT  ###
#######################################################

#mount /dev/nvme0n1p3 /mnt/windows/

# To check systemd timers, if launching this script
# systemctl list-timers

# $backupDir SHOULD BE DEFINED IN YOUR /etc/fstab, WITH THE noauto OPTION
#backupDir="/backup"

# No trailing or preceding slash
backupFolder="framework"

# The remote server to backup to
# You will probably need to manually create some folders for the first backup
server="root@10.0.0.200"
serverPort="2222"

# THE UUID of the drive you want to backup to
# This entry should exist in your fstab, and will auto-mount
# The folder it mounts to will automatically be detected
driveUUID="166cbbab-ff1d-4bc3-96e0-529b6c689613"

# WHAT FOLDERS DO YOU WANT TO BACKUP?
# Do not put a trailing slash, I'm too lazy to parse that!
# Use Absolute paths
# "/mnt/windows/Users/jfaku/Desktop/AHK" "/mnt/windows/Users/jfaku/Documents/Personal" 
targetFolders=( "/usr/local" "/etc" "/root" "/home" )
#targetFolders=( "/root/pacman" )

# WHAT FOLDERS DO YOU WANT TO EXCLUDE (like .gitignore)
exclude=( "node_modules/" "cache/" ".cache/" )

#ADD ANY EXTRA DESIRED RSYNC PARAMS
# This is also ammended by $OPT below
# Run quietly and normally
#rsyncParams="-a --delete --quiet"
# Show progress bars
rsyncParams="--delete --info=progress2 --info=name0"

update_jake_os.sh







##############################################################
###  THE REST OF THIS SCRIPT SHOULD NOT NEED MODIFICATION  ###
##############################################################

# Check if the script is running as root
if [[ $EUID -ne 0 ]]
then
    echo "!!!  This script must be run as root  !!!"
    exit
fi


# Mount the backup drive
#echo "!!!  Mounting the backup drive  !!!"
#mount -U "$driveUUID"

# Parse its mount directory
#backupDir="$(cat /etc/fstab | grep $driveUUID | awk '{print $2}')"
#backupDir="/backup"

#echo "!!! Drive mounted to backup directory: $backupDir  !!!"

# Make folders if they don't exist. Otherwise do nothing
#mkdir -p $backupDir/$backupFolder

# Sanity check
#if [[ ! -d "$backupDir/$backupFolder" ]]
#then
#	echo "!!!  Unable to find or automatically create $backupDir/$backupFolder  !!!"
#	exit
#fi

echo "!!!  Starting Backup to $backupDir/$backupFolder  !!!"


# Prune orphan packages
echo "!!!  Pruning orphan packages  !!!"
pacman -Qtdq | pacman -Rns -

# Extra info for potentially unused packages:
# Remove "--print" to remove them
# pacman -Qqd | pacman -Rsu --print -

# Methodology adapted from: https://wiki.archlinux.org/title/Rsync#Snapshot_backup
# The rough idea is to create a new folder based on the date, and back up to there
# This snapshot approach would obviously take up a lot of space
# The --link-dest option tells rsync to use hardlinks to point to unchanged files
# Rather than copying the actual file

OPT="-aPh"
date=`date "+%Y-%b-%d_%T"`

# Save Pacman packages
echo "!!!  Saving pacman packages to $backupDir/$backupFolder/$date/*pacman.txt  !!!"
pacman -Qe > "/root/pacman/pacman.txt"
pacman -Qm > "/root/pacman/non_pacman.txt"

# To restore (with pacman, yay requires manual installation):
# pacman -S --needed - < pacman.txt
# yay -S --needed - < non_pacman.txt


# Snapshot folder
SNAP="$backupDir/$backupFolder/"
# "Last" snapshot folder. This is updated as a symlink from the latest snapshot
LAST="$backupDir/$backupFolder/last"

# Build out an array of multiple --exclude statements
for path in "${exclude[@]}"
do
   excludeOpts="$excludeOpts --exclude $path"
done

echo "!!!  Preparing to transfer data  !!!"

# Loop through the target folders and backup each
for folder in "${targetFolders[@]}"
do
	LINK="--link-dest=$LAST$folder/"

	echo "!!!  Backup up folder '$folder' to '${SNAP}$date$folder'  !!!"

	ssh $server -p $serverPort "mkdir -p $SNAP$date$folder"
	
	#rsync $rsyncParams $excludeOpts $OPT $LINK "$folder" "${SNAP}$date$folder"


	# For transfers over the web
	rsync $rsyncParams $excludeOpts $OPT $LINK --rsh="ssh -p $serverPort" "$folder" "$server:${SNAP}$date$folder"
	

done

echo "!!!  Updating simlinks  !!!"
ssh $server -p $serverPort "rm -f $LAST; ln -s ${SNAP}$date $LAST"

echo "!!!  Backup complete!  !!!"
echo "!!!  Unmounting backup drive  !!"