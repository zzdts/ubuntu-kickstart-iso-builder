#!/usr/bin/env bash

# Default Folders
isooutputpath="$(pwd)/builds"  # destination folder to store the final iso file
configfilespath="$(pwd)/cfg"
isoinpath="$(pwd)/iso"

# Defaut File names
kscfg="ks.cfg"
txtcfg="txt.cfg"

# Temporary folder for ISO Generation. Cleaned up after each execution
isomnt="/mnt/iso"
isotmp="/tmp/iso"
txtcfgpath="$isotmp/isolinux/$txtcfg"


# User selected options
selectediso=""
selectedconfig=""


# define function to check if program is installed
# courtesy of https://gist.github.com/JamieMason/4761049
function program_is_installed {
    # set to 1 initially
    local return_=1
    # set to 0 if not found
    type $1 >/dev/null 2>&1 || { local return_=0; }
    # return value
    echo $return_
}

# print a pretty header
echo
echo " +---------------------------------------------------+"
echo " |            UNATTENDED UBUNTU ISO MAKER            |"
echo " +---------------------------------------------------+"
echo

# ask if script runs without sudo or root priveleges
if [ $currentuser != "root" ]; then
    echo " you need sudo privileges to run this script, or run it as root"
    exit 1
fi

# check for mkisofs availability

# List and ask which ISO File should be used
https://askubuntu.com/questions/682095/create-bash-menu-based-on-file-list-map-files-to-numbers

# List and ask which Kickstart file should be used
https://askubuntu.com/questions/682095/create-bash-menu-based-on-file-list-map-files-to-numbers

# Mount ISO file
mkdir $isomnt
mount -o loop $isoin $isomnt

# RSync ISO files to Temporary directory
mkdir $isotmp
rsync -a $isomnt $isotmp

# Change permission on all files
chmod -R 777 $isotmp

# Copy ks.cfg file in root folder
cp "$selectedconfig/$kscfg" $isotmp

# Change boot menu default action to autoinstall
cp $txtcfgpath $("$txtcfgpath.default")
## REPLACE "default live" by "default autoinstall"
sed -i '/default live/c\default autoinstall' $txtcfgpath

# happend boot menu options for autoconfig
cat "$selectedconfig/$txtcfg" >> $txtcfgpath

# build iso image
cd $isotmp
mkisofs -D -r -V “$IMAGE_NAME” -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o "$isooutputpath/autoinstall.iso" .

# unmount iso image
umount $isomnt

# clean up tempfolders
rm -dfr $isotmp
