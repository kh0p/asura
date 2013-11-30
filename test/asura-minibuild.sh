### Known issues (from arch wiki)
## Troubleshooting boot problems
# If you are using an Intel video chipset and the screen goes blank 
# during the boot process, the problem is likely an issue with Kernel
# Mode Setting. A possible workaround may be achieved by rebooting 
# and pressing e over the entry that you are trying to boot (i686 or 
# x86_64). At the end of the string type nomodeset and press Enter. 
# Alternatively, try 'video=SVIDEO-1:d' which, if it works, will not 
# disable kernel mode setting. You can also try 'i915.modeset=0'.
## 

# config: globals and defaults
errnum=
random="date +%N | sed -e 's/000$//' -e 's/^0//'"
PACKAGES=""
arch=""
key_layout=us
def_font=Lat2-Terminus16
localegen=/locale-gen.patch
lang=en_US.UTF-8
partition=
pkglist="$*"

pacman_args=( $pkglist )
pacman_args+=(--noconfirm)
pacman_args+=(--cachedir="$newroot/var/cache/pacman/pkg")

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

}

make_logfile ()
{
	echo -n "ASURA BUILD ERROR LOG" >> builderror.log
	date >> builderror.log
	echo "=========================================" >> builderror.log
}

make_logfile

## Here will go: 
# 1. Choosing architecture
# 2. Choosing key layout.
# 3. Choosing locale.gen patch
# For now it's not here, because I'm testing with only one set of 
# settings at the moment.


## Loading key layout 
#
echo "Setting your key layout to '$key_layout' (...)"
loadkeys $key_layout
if [[ $? -eq 0 ]]; then
	echo "[+] Your key layout ('$key_layout') is successfully set."
else
	$errnum=1
	echo "[!] error$errnum: command: 'loadkeys'" >> builderror.log
	error_sig
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


## Edditing and running locale-gen - setting up language 
#
echo "Editting your locale.gen file with '$localegen'(...)"
patch -p1 < /locale-gen.patch
if [[ $? -eq 0 ]]; then
	echo "[+] Your locale.gen file is successfully edited."
else
	$errnum=1
	echo "[!] error$errnum: command: 'patch -p1'" >> builderror.log
	error_sig
fi

echo "Running locale-gen command (...)"
locale-gen
if [[ $? -eq 0 ]]; then
	echo "[+] Locale-gen is successful."
else
	$errnum=1
	echo "[!] error$errnum: command: 'locale-gen'" >> builderror.log
	error_sig
fi

echo "Exporting LANG ('$lang') (...)"
export LANG=$lang
if [[ $? -eq 0 ]]; then
	echo "[+] LANG is exported successfully."
else
	$errnum=1
	echo "[!] error$errnum: command: 'export LANG=$lang'" >> builderror.log
	error_sig
fi

## Testing and configuring network connection
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