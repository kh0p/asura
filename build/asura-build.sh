### Asura build script @2013
##
## Script is created to work with latest arch linux iso release [1],
## on every architecture. For now, by default, it installs gnome 
## and awesome-gnome from official arch repositories. It'll also 
## contain few packs of recommended utilities.
##
## I've implemented few functions from AUI script:
## 	https://github.com/helmuthdu/aui/blob/master/sharedfuncs
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

SYSDIR=build
MOUNTPOINT=/mnt
mkfstype=mkfs.ext4
dewm="gnome xorg awesome-gnome"
key_layout=us
lang=en_US.UTF-8
def_font=Lat2-Terminus16
zonetime=Poland
HOSTNAME="test"
HOME_DIR=home
autofdisk=yes
initramfs="-p linux"
EDITOR=nano # for test

BOOT_SIZE=+64M
SWAP_SIZE=+1024M
HOME_SIZE= #rest

arch_chroot() 
{ 
    arch-chroot $MOUNTPOINT/$SYSDIR /bin/bash -c "${1}"
}

format_color ()
{
	table=$(for i in {16..21} {21..16} ; do echo -en "\e[38;5;${i}m#\e[0m" ; done ; echo)
	default=\e[39m
	l_green=\e[92m
	l_red=\e[91m
}

error_sig ()
{
	echo "asura error:$errnum"
	echo -n "Description: "
	case $errnum in
		1) echo "command returned non-zero value";;
		2) echo "command returned non-zero value - checking others";;
		3) echo "command returned non-zero value - different possibilities checked";;
	esac
	echo "Check 'troubleshooting' in 'doc' directory"
	echo "Check github issues: https://github.com/defm03/asura/issues"
	echo "and share your 'builderror.log' file."
}

std_check ()
{
	if [ $? -eq 0 ]; then
		echo $success_msg
	else
		$errnum=1
		echo -e "[!] error$errnum: command: '$cmd_name'" >> builderror.log
		error_sig		
	fi
}

partition_note ()
{
	echo "Default, standard partition model: "
	echo "	sda1 = boot (small amount of space)"
	echo "	sda2 = swap (moderate amount of space)"
	echo "	sda3 = root (biggest partition)"
	echo -n "You like that model? (y/n) "; read yesno
	if [ "$yesno" == 'y' ]; then
		BOOT=/dev/sda1
		SWAP=/dev/sda2
		ROOT=/dev/sda3
	else
		# I'll work on it later
		exit 1
	fi
}

partition_mount ()
{
	echo "Mounting sda3 on $MOUNTPOINT/$SYSDIR (...)"
	mount $ROOT $MOUNTPOINT/$SYSDIR
	cmd_name=mount; std_check
	
	mkdir $MOUNTPOINT/$SYSDIR/swapf; mount $SWAP $MOUNTPOINT/$SYSDIR/swapf 
	cmd_name=mount; std_check

	mkdir $MOUNTPOINT/$SYSDIR/boot; mount $BOOT $MOUNTPOINT/$SYSDIR/boot
	cmd_name=mount; std_check
}

partition_umount ()
{
	umount /mnt/{swapf,home,}
}

fstab_config ()
{
	if [[ ! -f $MOUNTPOINT/etc/fstab.asura ]]; then
		cp $MOUNTPOINT/$SYSDIR/etc/fstab $MOUNTPOINT/$SYSDIR/etc/fstab.asura
	else
		cp $MOUNTPOINT/$SYSDIR/etc/fstab.asura $MOUNTPOINT/$SYSDIR/etc/fstab
	fi
	FSTAB=("DEV" "UUID" "LABEL");
	select OPT in "${FSTAB[@]}"; do
		case "$REPLY" in
			1) genfstab -p $MOUNTPOINT/$SYSDIR >> $MOUNTPOINT/$SYSDIR/etc/fstab ;;
			2) genfstab -U $MOUNTPOINT/$SYSDIR >> $MOUNTPOINT/$SYSDIR/etc/fstab ;;
			3) genfstab -L $MOUNTPOINT/$SYSDIR >> $MOUNTPOINT/$SYSDIR/etc/fstab ;;
			*) invalid_option ;;
		esac
		[[ -n $OPT ]] && break
	done
	echo "Review your fstab"
	[[ -f $MOUNTPOINT/$SYSDIR/swapfile ]] && sed -i "s/\\${MOUNTPOINT/$SYSDIR}//" $MOUNTPOINT/$SYSDIR/etc/fstab
	$EDITOR $MOUNTPOINT/etc/fstab
}

install_bootloader(){
	echo "BOOTLOADER - https://wiki.archlinux.org/index.php/Bootloader"
	echo "The boot loader is responsible for loading the kernel and 
	initial RAM disk before initiating the boot process."
	
	bootloader=("Grub2" "Syslinux" "Skip")
	echo -e "Install bootloader:\n"
	select BOOTLOADER in "${bootloader[@]}"; do
		case "$REPLY" in
			1)
				#make grub automatically detect others OS
				if [[ $UEFI -eq 1 ]]; then
					pacstrap $MOUNTPOINT/$SYSDIR grub efibootmgr
				else
					pacstrap $MOUNTPOINT/$SYSDIR grub
				fi
				pacstrap $MOUNTPOINT/$SYSDIR os-prober
				break
				;;
			2)
				pacstrap $MOUNTPOINT/$SYSDIR syslinux
				break
				;;
			3)
				break
				;;
			*)
				invalid_option
				;;
		esac
	done
}

bootloader_config ()
{
	case $BOOTLOADER in
		Grub2)
			arch_chroot "modprobe dm-mod"
			grub_install_mode=("[MBR|UEFI] Automatic" "Manual")
			echo -e "Grub Install:\n"
			select OPT in "${grub_install_mode[@]}"; do
				case "$REPLY" in
					1)
						if [[ $UEFI -eq 1 ]]; then
							arch_chroot "mount -t efivarfs efivarfs /sys/firmware/efi/efivars && grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck && umount -R /sys/firmware/efi/efivars"
						else
							arch_chroot "grub-install --recheck ${BOOT_DEVICE}"
						fi
						break
						;;
					2)
						arch-chroot $MOUNTPOINT/$SYSDIR
						break
						;;
					*)
						echo "Invalid option"
						;;
				esac
			done
			arch_chroot "grub-mkconfig -o /boot/grub/grub.cfg"
			;;
		Syslinux)
			syslinux_install_mode=("[MBR] Automatic" "[PARTITION] Automatic" "Manual")
			echo -e "Syslinux Install:\n"
			select OPT in "{syslinux_install_mode[@]}"; do
				case "$REPLY" in
					1)
						arch_chroot "syslinux-install_update -iam"
						;;
					2)
						arch_chroot "syslinux-install_update -i"
						break
						;;
					3)
						echo "Your boot partition, on which you plan to install Syslinux, must contain a FAT, 
						ext2, ext3, ext4, or Btrfs file system. You should install it on a mounted directory, 
						not a /dev/sdXY device. You do not have to install it on the root directory of a file 
						system, e.g., with device /dev/sda1 mounted on /boot you can install Syslinux in the 
						syslinux directory"
						echo "[!] mkdir /boot/syslinux\nextlinux --install /boot/syslinux"
						arch_chroot $MOUNTPOINT/$SYSDIR
						break
						;;
					*)
						echo "Invalid option"
						;;
				esac
			done
		;;
	esac
}

make_logfile ()
{
	echo -n "ASURA BUILD ERROR LOG " >> builderror.log
	date >> builderror.log
	echo "==================================================" >> builderror.log
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
	TOTAL_MEM=$(grep MemTotal /proc/meminfo | awk '{print $2/1024}' | sed 's/\..*//')

	(echo n; echo p; echo 1; echo ; echo $BOOT_SIZE;
	 echo a;
	 echo n; echo p; echo 2; echo ; echo $SWAP_SIZE;
	 echo t; echo 2; echo 82;
	 echo n; echo p; echo 3; echo ; echo ; echo w) | fdisk /dev/sda
	cmd_name=fdisk; success_msg="[+] Done with allocating space for $BOOT, $SWAP and $ROOT"; std_check

	# sfdisk -d /dev/sda > disk.layout; cmd_name=sfdisk
	# success_msg="[+] Done with saving your disk partitions table"
	# echo "Displaying your partition layout (...)"
	# cat disk.layouts

	echo "Setting $BOOT and $ROOT partition type to ext4 (...)"
	$mkfstype $BOOT; cmd_name="mkfs.ext4/boot"
	success_msg="[+] Successfully set $BOOT to ext4"; std_check
	$mkfstype $ROOT; cmd_name="mkfs.ext4/home"
	success_msg="[+] Successfully set $ROOT to ext4"; std_check

	echo "Creating and starting swap partition (...)"
	mkswap $SWAP; cmd_name=mkswap; std_check 
	swapon $SWAP; cmd_name=swapon; std_check

	partition_mount
else
	echo "Running 'cfdisk' - tool to set up your partitions (...)"
	cfdisk; cmd_name=mount; std_check
fi


## Network tests

network_test ()
{
	echo "Running ping command on www.google.com (...)"
	ping -c 5 www.google.com
	if [ $? -ne 0 ]; then
		echo -e "[!] Ping on www.google.com failed."
		errnum=2
		echo -e "[!] error$errnum: command: 'ping'" >> builderror.log
		error_sig

		echo "Re-sending ping on www.google.com (...)"
		ping -c 5 www.google.com
		case $? in
			1) echo -e "[!] PING: exit_status:1 " >> builderreor.log; $errnum=3; error_sig;;
			2) echo -e "[!] PING: exit status:2 " >> builderreor.log; $errnum=3; error_sig;;
		esac
	else
		echo -e "[+] At least one response was heard from the specified host."
		echo -e "[+] No problems with network connection."
	fi	
}
echo -n "Do you want to test your network now? (y/n) "; read yesno
if [ "$yesno" == 'y' ]; then 
	network_test 
fi

network_test_aui ()
{
	XPINGS=$(( $XPINGS + 1 ))
	ping_gw () {
		IP_ADDR=`ip r | grep default | cut -d ' ' -f 3`
		[[ -z $IP_ADDR ]] && IP_ADDR="8.8.8.8"
		ping -q -w 1 -c 1 ${IP_ADDR} > /dev/null && return 1 || return 0
	}
	WIRED_DEV=`ip link | grep enp | awk '{print $2}'| sed 's/://'`
	WIRELESS_DEV=`ip link | grep wlp | awk '{print $2}'| sed 's/://'`
	if ping_gw; then
		echo "ERROR! Connection not Found."
		echo "Network setup"
		conn_type_list=("Wired Automatic" "Wired Manual" "Wireless")
		select CONNECTION_TYPE in "${conn_type_list[@]}"; do
			case "$REPLY" in
				1)
					systemctl start dhcpcd@${WIRED_DEV}.service
					break
					;;
				2)
					systemctl stop dhcpcd@${WIRED_DEV}.service
					read -p "IP Address: " IP_ADDR
					read -p "Submask: " SUBMASK
					read -p "Gateway: " GATEWAY
					ip link set ${WIRED_DEV} up
					ip addr add ${IP_ADDR}/${SUBMASK} dev ${WIRED_DEV}
					ip route add default via ${GATEWAY}		
					$EDITOR /etc/resolv.conf
					break
					;;
				3)
					ip link set ${WIRELESS_DEV} up
					wifi-menu ${WIRELESS_DEV}
					break
					;;
				*)
					echo "Invalid option"
					;;
			esac
		done
		if [[ $XPINGS -gt 2 ]]; then
			echo "Can't establish connection. exiting..."
			exit 1
		fi
		check_connection
	fi		
}


## System installation
# pacstrap, genfstab and chrooting here

echo "Starting pacstrap - arch installation script (...)"
pacstrap -i /mnt base base-devel btrfs-progs ntp; cmd_name=pacstrap; std_check
WIRELESS_DEV=`ip link | grep wlp | awk '{print $2}'| sed 's/://'`
if [[ -n $WIRELESS_DEV ]]; then
	pacstrap $MOUNTPOINT/$SYSDIR iw wireless_tools wpa_actiond wpa_supplicant dialog
fi
echo "Generating fstab file (...)"
#genfstab -U -p /mnt  :  sed 's/rw,realtime,data=ordered/defaults,realtime/' >> /mnt/etc/fstab
#cmd_name="genfstab (-U -p /mnt  :  sed 's/rw,realtime,data=ordered/defaults,realtime/')"; std_check
#From AIS (https://github.com/helmuthdu/aui/blob/master/ais):
fstab_config

arch-chroot /mnt; cmd_name=arch-chroot; std_check


## Key layout and default font

key_build () 
{
	echo "Setting your key layout to '$key_layout' (...)"
	loadkeys $key_layout; cmd_name=loadkeys
	success_msg="[+] Your key layout ('$key_layout') is successfully set."
	std_check

	echo "Setting your font to '$def_font' (...)"
	setfont $def_font; cmd_name=setfont
	success_msg="[+] Your font ('$def_font') is successfully set."
	std_check
}
key_build


## Editing and running locale-gen - setting up language 

echo "Editing your locale.gen file with '$localegen'(...)"
patch -p1 < /locale-gen.patch; cmd_name="patch -p1"
success_msg="[+] Your locale.gen file is successfully edited."
std_check

echo "Running locale-gen command (...)"
locale-gen; cmd_name=locale-gen
success_msg="[+] Locale-gen is successful."; std_check

echo LANG=$lang > /etc/locale.conf

echo "Exporting LANG ('$lang') (...)"
export LANG=$lang; cmd_name="export LANG"
success_msg="[+] LANG is exported successfully."; std_check


## Zonetime and hwclock

echo "Changing your default zonetime info (...)"
ln -s /usr/share/zonetime/$zonetime /etc/localetime
hwclock --systohc --utc; cmd_name="hwclock --systohc --utc"
success_msg="[+] Successfully set hwclock"; std_check


## unset unneeded variables
unset key_layout; unset mkfstype
##
# Second part of build
##


## building an initramfs CPIO image
# mkinitcpio - is the next generation of initramfs creation. 
# /usr/lib/modules - available kernel versions
# mkinitcpio -g /boot/linux.img -k [version]
# https://wiki.archlinux.org/index.php/mkinitcpio - archwiki

echo "Building an initramfs CPIO image (...)"
mkinitcpio $initramfs; cmd_name=mkinitcpio
success_msg="[+] Successful build of an initramfs CPIO image"; std_check


## Creating user

yesno=
echo -n "Do you want to create new user? (y/n) "; read yesno
if [ "$yesno" == 'y' ]; then
	echo -n "Do you want to set root password? (y/n) "; read yesno
	if [ "$yesno" == 'y' ]; then
		passwd; cmd_name=passwd; std_check
	else
		echo "Continue ..."
	fi
	usrname=
	echo -n "Enter your username: "; read usrname
	useradd -m -g users -G wheel -s /bin/bash $usrname
	cmd_name="useradd -m -g users -G wheel -s /bin/bash $usrname"; std_check
	echo -n "You want password for your user? (y/n) "; read yesno
	if [ "$yesno" == 'y' ]; then
		passwd $usrname
	fi
fi


## Installation and configuration of bootloader

install_bootloader
bootloader_config


## umount

umount {proc,sys,dev,boot,swapf}
umount /mnt

## unset uneeded variables
unset BOOT; unset SWAP; unset ROOT; unset HOME_DIR; 