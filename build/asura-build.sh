### Asura build script @2013
##
## Script is created to work with latest arch linux iso release [1],
## on every architecture. For now, by default, it installs gnome 
## and awesome-gnome from official arch repositories. It'll also 
## contain few packs of recommended utilities.
## 
## [1]: https://projects.archlinux.org/users/dieter/releng.git/
##	This is link to releng repo, not latest release, but it's worth
##	checking, so I putted it here.
###

###
# For future development of script:
# wget "https://projects.archlinux.org/arch-install-scripts.git/plain/pacstrap.in"
# wget "https://projects.archlinux.org/arch-install-scripts.git/plain/genfstab.in"
# source pacstrap.in
# source genfstab.in
###

### License:
## Asura - Script for dynamic arch install 
## Copyright (C) 2013 Kamil Żak (defm03/qualia) defm03@outlook.jp
##
## This program is free software: you can redistribute it and/or modify it under the
## terms of the GNU General Public License as published by the Free Software Foundation,
## either version 3 of the License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
## without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
## See the GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License along with this program. 
## If not, see http://www.gnu.org/licenses/.
###

# config: globals; defaults
errnum= #${errnum:-0}
success_msg= #${success_msg:-"[+]"}
cmd_name= #${cmd_name:-"noname"}

mkfstype=mkfs.ext4
dewm="gnome xorg awesome-gnome"
key_layout=us
lang=en_US.UTF-8
def_font=Lat2-Terminus16
zonetime=Poland
HOSTNAME="test"
autofdisk=yes
RAMdisk="mkinitcpio -p linux"

BOOT_SIZE=+64M
SWAP_SIZE=+1024M
HOME_SIZE= #rest

format_color ()
{
	table=$(for i in {16..21} {21..16} ; do echo -en "\e[38;5;${i}m#\e[0m" ; done ; echo)
	default=\e[39m
	l_green=\e[92m
	l_red=\e[91m
}
format_color

error_sig ()
{
	echo "asura error:$errnum"
	echo -n "Description: "
	case $errnum in
		1) echo "command returned non-zero value";;
		2) echo "command returned non-zero value - checking others";;
		3) echo "command returned non-zero value - different possibilities checked";;
	esac
	echo "Check '\e[92mtroubleshooting\e[39m' in '\e[92mdoc\e[39m' directory"
	echo "Check github issues: https://github.com/defm03/asura/issues"
	echo "and share your '\e[92mbuilderror.log\e[39m' file."
}

std_check ()
{
	if [ $? -eq 0 ]; then
		echo $success_msg
	else
		$errnum=1
		echo -e "[$l_green ! $default] error$errnum: command: '$cmd_name'" >> builderror.log
		error_sig		
	fi
}

partition_note ()
{
	echo "Default, standard partition model: "
	echo "	sda1 = boot (small amount of space)"
	echo "	sda2 = swap (moderate amount of space)"
	echo "	sda3 = home (biggest partition)"
	echo -n "You like that model? (y/n) "; read yesno
	if [ "$yesno" == 'y' ]; then
		BOOT=/dev/sda1
		SWAP=/dev/sda2
		HOMEp=/dev/sda3
	else
		# I'll work on it later
		exit 1
	fi
}

make_logfile ()
{
	echo -n "ASURA BUILD ERROR LOG " >> builderror.log
	date >> builderror.log
	echo "=========================================" >> builderror.log
}

make_logfile


## Partitioning
# using by default: 3 partitions (check 'partiton_note'), ext4,
# cfdisk to make them and mounts them; it also turns one partition
# into swap and runs swapon on it. 'pacstrap' and umount is done in 
# next stages.

partition_note
read -p "Press any key to continue... " -n1 -s
if [ "$autofdisk" == "yes" ];then
	(echo n; echo p; echo 1; echo ; echo $BOOT_SIZE;
	 echo a;
	 echo n; echo p; echo 2; echo ; echo $SWAP_SIZE;
	 echo t; echo ; echo 82;
	 echo n; echo p; echo 3; echo ; echo ; echo w) | fdisk /dev/sda
	cmd_name=fdisk; success_msg="[$l_green + $default] Done with allocating space for $BOOT, $SWAP and $HOMEp"; std_check

	sfdisk -d /dev/sda > disk.layout; cmd_name=sfdisk
	success_msg="[$l_green + $default] Done with saving your disk partitions table"
	echo "Displaying your partition layout (...)"
	cat disk.layouts
else
	cfdisk
fi

echo "Setting partition type to ext4 (...)"
$mkfstype $BOOT; cmd_name="mkfs.ext4/boot"
success_msg="[+] Successfully set $BOOT to ext4"; std_check
$mkfstype $HOMEp; cmd_name="mkfs.ext4/home"
success_msg="[+] Successfully set $HOMEp to ext4"; std_check

echo "Creating and starting swap partition (...)"
mkswap $SWAP; cmd_name=mkswap
success_msg=""; std_check 
swapon $SWAP; cmd_name=swapon; std_check

echo "Mounting sda3 on home directory (...)"
mkdir $HOME_DIR; mount $HOMEp $HOME_DIR
cmd_name=mount; std_check


## System installation

echo "Starting pacstrap - arch installation script (...)"
pacstrap -i /mnt base base-devel; cmd_name=pacstrap; std_check

echo "Generating fstab file (...)"
genfstab -U -p /mnt  :  sed 's/rw,realtime,data=ordered/defaults,realtime/' >> /mnt/etc/fstab
cmd_name="genfstab (-U -p /mnt  :  sed 's/rw,realtime,data=ordered/defaults,realtime/')"; std_check

arch-chroot /mnt; cmd_name=arch-chroot; std_check


## Key layout and default font

echo "Setting your key layout to '$key_layout' (...)"
loadkeys $key_layout; cmd_name=loadkeys
success_msg="[$l_green + $default] Your key layout ('$key_layout') is successfully set."
std_check

echo "Setting your font to '$def_font' (...)"
setfont $def_font; cmd_name=setfont
success_msg="[$l_green + $default] Your font ('$def_font') is successfully set."
std_check


## Editing and running locale-gen - setting up language 

echo "Editing your locale.gen file with '$localegen'(...)"
patch -p1 < /locale-gen.patch; cmd_name="patch -p1"
success_msg="[$l_green + $default] Your locale.gen file is successfully edited."
std_check

echo "Running locale-gen command (...)"
locale-gen; cmd_name=locale-gen
success_msg="[$l_green + $default] Locale-gen is successful."; std_check

echo LANG=$lang > /etc/locale.conf

echo "Exporting LANG ('$lang') (...)"
export LANG=$lang; cmd_name="export LANG"
success_msg="[$l_green + $default] LANG is exported successfully."; std_check


## Zonetime and hwclock

echo "Changing your default zonetime info (...)"
ln -s /usr/share/zonetime/$zonetime /etc/localetime
hwclock --systohc --utc; cmd_name="hwclock --systohc --utc"
success_msg="[$l_green + $default] Successfully set hwclock"; std_check


## Network build up

echo "Running ping command on www.google.com (...)"
ping -c 5 www.google.com
if [ $? -ne 0 ]; then
	echo -e "[$l_red ! $default] Ping on www.google.com failed."
	errnum=2
	echo -e "[$l_red ! $default] error$errnum: command: 'ping'" >> builderror.log
	error_sig

	echo "Re-sending ping on www.google.com (...)"
	ping -c 5 www.google.com
	case $? in
		1) echo -e "[$l_red ! $default] PING: exit_status:1 " >> builderreor.log; $errnum=3; error_sig;;
		2) echo -e "[$l_red ! $default] PING: exit status:2 " >> builderreor.log; $errnum=3; error_sig;;
	esac
else
	echo -e "[$l_green + $default] At least one response was heard from the specified host."
	echo -e "[$l_green + $default] No problems with network connection."
fi


## unset unneeded variables
unset BOOT; unset SWAP; unset HOME; unset key_layout
unset HOME_DIR; unset mkfstype


##
# Second part of build - packages
##