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

pack_gfx () 
{}

pack_email ()
{}

pack_security ()
{}

pack_torrent ()
{}