# Script is created to work with latest arch linux iso release [1],
# on every architecture. For now, by default, it installs gnome 
# and awesome-gnome from official arch repositories. It also contains
# few packs of recommended utilities.
# 
# [1]: https://projects.archlinux.org/users/dieter/releng.git/


## For future development of script:
#
# wget "https://projects.archlinux.org/arch-install-scripts.git/plain/pacstrap.in"
# wget "https://projects.archlinux.org/arch-install-scripts.git/plain/genfstab.in"
#
# source pacstrap.in
# source genfstab.in
##

# config: globals; defaults
errnum= #${errnum:-0}
success_msg= #${success_msg:-"[+]"}
cmd_name= #${cmd_name:-"noname"}

mkfstype=mkfs.ext4
dewm="gnome xorg awesome-gnome"
key_layout=us
def_font=Lat2-Terminus16

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
	if [[ $? -eq 1 ]]; then
		echo $success_msg
	else
		$errnum=1
		echo "[!] error$errnum: command: '$cmd_name'" >> builderror.log
		error_sig		
	fi
}

partiton_note()
{
	echo "Default, standard partition model: "
	echo "	sda1 = boot (small amount of space)"
	echo "	sda2 = swap (moderate amount of space)"
	echo "	sda3 = home (biggest partition)"
	echo -n "You like that model? (y/n)"; read yesno
	if [[ yesno -eq 'y' ]]; then
		BOOT=/dev/sda1
		SWAP=/dev/sda2
		HOME=/dev/sda3
	else
		# I'll work on it later
		exit 1
	fi

}

make_logfile ()
{
	echo -n "ASURA BUILD ERROR LOG" >> builderror.log
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
cfdisk; $cmd_name=cfdisk
$success_msg="[+] Done with giving space for $BOOT, $SWAP and $HOME"; std_check

echo "Setting partition type to ext4 (...)"
$mkfstype $BOOT; $cmd_name="mkfs.ext4/boot"
$success_msg="[+] Successfully set $BOOT to ext4"; std_check
$mkfstype $HOME; $cmd_name="mkfs.ext4/home"
$success_msg="[+] Successfully set $HOME to ext4"; std_check

echo "Creating and starting swap partition (...)"
mkswap $SWAP; $cmd_name="mkswap"
$success_msg=""; std_check 
swapon $SWAP; $cmd_name="swapon"; std_check

echo "Mounting sda3 on home directory (...)"
mkdir $HOME_DIR; mount $HOME $HOME_DIR
$cmd_name=mount; std_check


## System installation
#
echo "Starting pacstrap - arch installation script (...)"
pacstrap -i /mnt base base-devel; $cmd_name="pacstrap"; std_check

echo "Generating fstab file (...)"
genfstab -U -p /mnt  :  sed 's/rw,realtime,data=ordered/defaults,realtime/' >> /mnt/etc/fstab
$cmd_name="genfstab (-U -p /mnt  :  sed 's/rw,realtime,data=ordered/defaults,realtime/')"; std_check

arch-chroot /mnt; $cmd_name=arch-chroot; std_check


## 
#
echo "Setting your key layout to '$key_layout' (...)"
loadkeys $key_layout
if [[ $? -eq 0 ]]; then
	echo "[+] Your key layout ('$key_layout') is successfully set."
else
	$cmd
fi


## Setting font 
#
echo "Setting your font to '$def_font' (...)"
setfont $def_font
if [[ $? -eq 0 ]]; then
	echo "[+] Your font ('$def_font') is successfully set."
else
	$errnum=1
	echo "[!] error$errnum: command: 'setfont'" >> builderror.log
	error_sig
fi

## Network build up
#
echo "Running ping command on www.google.com (...)"
ping -c 5 www.google.com
if [[ $? -ne 0 ]]; then
	echo "[!] Ping on www.google.com failed."
	$errnum=2
	echo "[!] error$errnum: command: 'ping'" >> builderror.log
	error_sig

	echo "Re-sending ping on www.google.com (...)"
	ping -c 5 www.google.com
	case $? in
		1) echo "[!] PING: exit_status:1 " >> builderreor.log; $errnum=3; error_sig;;
		2) echo "[!] PING: exit status:2 " >> builderreor.log; $errnum=3; error_sig;;
	esac
else
	echo "[+] At least one response was heard from the specified host."
	echo "[+] No problems with network connection."
fi