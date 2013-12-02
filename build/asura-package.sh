source asura-shared.sh

argsparse ()
{
	TEMP=$(getopt -n $PROGRAM_NAME -o S:h \
	--long install-package:,help \
	-- "$@")      
	
	[ $? = 0 ] || die "Error parsing arguments. Try $PROGRAM_NAME --help"

	eval set -- "$TEMP"
	while true; do
		case $1 in
			-S|--install-package)
				INSTALL_PACKAGE="$2";
				shift; continue
				;;
			-h|--help)
				echo "Asura - package build  Copyright (C) 2013  Kamil Żak (defm03)"
				echo "This program comes with ABSOLUTELY NO WARRANTY."
				echo "This is free software, and you are welcome to redistribute it"
				echo "under certain conditions; for details look into LICENSE.\n"
				echo -n "Usage: "
				echo "asura-package <operation> [options]"
				echo "	-h --help:"
				echo "		Display syntax for the given operation. If no operation was supplied then the general syntax is shown. "
				echo "	-S --install-package:"
				echo "		Runs install script for given packages."
				;;
		esac
	done
}

pack_gfx()
{
	pack_de () {
		install_gnome ()
		{
			log_msg "Setting gnome USE flags in make.conf"
			SET_USE_FLAG make.conf "dbus gtk gnome"
			eselect_profile "desktop"

			gnome=("gnome" "gnome-light")
			echo -e "Install gnome:\n"
			select GNOME in "${gnome[@]}"; do
				case "$REPLY" in
					1)
						log_msg "Running emerge on gnome"
						echo emerge gnome
						;;
					2)
						log_msg "Running emerge on gnome-light"
						echo emerge gnome-light
						;;
					*)
						echo "Invalid option."
						;;
				esac
			done

			log_msg "Updating environment variables"
			echo env-update && source /etc/profile

			log_msg "Cleaning up the remaining services and user groups"
			
			log_msg "Setting up the DBUS service"
			echo /etc/init.d/dbus start

			# OPTIONAL
			# log_msg "Checking and adding users to plugdev"
			# getent group plugdev
			# gpasswd -a $usrname plugdev
		}
	}
}