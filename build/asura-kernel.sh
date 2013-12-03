source asura-shared.sh
SELinux_setrans_conf="setrans.conf" #/etc/selinux

SELinux ()
{	
	MAC_conf ()
	{
		MAC_category_new ()
		{
			# s0 portion is required, as MCS is implemented using SELinux's
			# Multi-Level Security (MLS) support. 
			CATEGORY=$1
			CNAME=$2
			"$CATEGORY:$CNAME" >> $SELinux_setrans_conf
		}

		MAC_category_ed ()
		{	
			# s = set; d = del; f = overwrite
			SWITCH=$1
			CATEGORY=$2
			FILENAME=$3
			case "$SWITCH" in
				s) 
					log_msg "Setting $CATEGORY category for $FILENAME"
					chcat +$CATEGORY $FILENAME 
					;;
				d)
					log_msg "Removing $CATEGORY category for $FILENAME"
					chcat -- -$CATEGORY $FILENAME 
					;;
				f)
					log_msg "Forced $CATEGORY category for $FILENAME"
					chcat $CATEGORY $FILENAME
					;;
				*)
					echo "Invalid option."
					;;
			esac
			
		}

		MAC_runcon ()
		{
			CATEGORY=$1
			PROGRAM=$2
			runcon -l $CATEGORY $PROGRAM
		}
	}
}