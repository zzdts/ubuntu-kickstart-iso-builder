#!/usr/bin/env bash

currentuser="$( whoami)"

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

# ask if script runs without sudo or root priveleges
if [ $currentuser != "root" ]; then
    echo
    echo " you need sudo privileges to run this script, or run it as root"
    exit 1
fi

# check for mkisofs availability

# List and ask which ISO File should be used
# Source : https://askubuntu.com/questions/682095/create-bash-menu-based-on-file-list-map-files-to-numbers

echo
echo "Select ISO File"

unset isofiles i
while IFS= read -r -d $'\0' f; do
  isofiles[i++]="$f"
done < <(find $isoinpath -maxdepth 1 -type f -name "*.iso" -print0 )

select opt in "${isofiles[@]}" "Stop the script"; do
  case $opt in
    *.iso)
      echo "ISO file $opt selected"
      selectediso=$opt
      break
      ;;
    "Stop the script")
      echo "You chose to stop"
      exit 0
      ;;
    *)
      echo "This is not a number"
      ;;
  esac
done


# List and ask which Kickstart file should be used

echo
echo "Select configuration folder"

unset configfilefolders i
while IFS= read -r -d $'\0' f; do
  configfilefolders[i++]="$f"
done < <(find $configfilespath -maxdepth 1 -mindepth 1 -type d -print0 )

select opt in "${configfilefolders[@]}" "Stop the script"; do
  case $opt in
    *.iso)
      selectedconfig=$opt
      break
      ;;
    "Stop the script")
      echo "You chose to stop"
      exit 0
      ;;
    *)
      echo "This is not a number"
      ;;
  esac
done

echo
echo "ISO file is : $selectediso"
echo "Config Folder is : $selectedconfig"
echo "ISO will be created in : $isooutputpath"
echo

# Temporary statement to prevent issues
exit 0

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
