#!/bin/sh

if [ -f /.CLEANRC ]
then
    exit 0
fi

# Extract Run level
Rlvl=`grep "^id:" /etc/inittab | cut -d ':' -f 2`

for link in `find /etc/rc${Rlvl}.d/ -type l`
do
    sfile="`basename $link`"
    if [ `echo $sfile | grep -c "^S"` -gt 0 ]
    then
	service=`echo $sfile | sed -e 's/^S[0-9][0-9]//g'`
	case $service in
	    "httpd") 
		echo "Leave $service"
		;;
	    "tim") 
		echo "Leave $service"
		;;
	    "tim-assist") 
		echo "Leave $service"
		;;
	    "crond") 
		echo "Leave $service"
		;;
	    "local") 
		echo "Leave $service"
		;;
	    "apmpacket") 
		echo "Leave $service"
		;;
	    *) echo "Disable $service"
		chkconfig $service off
		;;
	esac
    fi
done

# Clean up some more things. We need to disable whatever service that changes internals on this running CentOS
# Prevent Getty's from starting
sed -i 's/\[2345\]/\[1\]/g' /etc/init/start-ttys.conf

# Enabling httpd
chkconfig --levels 2345 httpd on

# Disabling udev
mv /sbin/udevd /sbin/udevd_orig
chmod 444 /sbin/udevd_orig
ln -s /bin/true /sbin/udevd

echo "Last run on `date`" > /.CLEANRC
