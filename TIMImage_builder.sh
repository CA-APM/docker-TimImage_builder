#!/bin/bash
#

# I want it to be verbose.
VERBOSE=false

##########################################################################
# Nothing to be changed below this point !
##########################################################################

# Programm Version
VER="$Revision: 1.0 $"

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

# Get Program-Name, shortened Version.
PROGNAME="`basename $0 .sh`"

# Execution PID.
PROG_PID=$$

# Directory we work in.
BASEDIR=`pwd`

# Build Date in reverse - Prefix to builds
DATE=`date +"%Y%m%d"`
# Date + Time
LDATE=`date +"%F @ %T"`

# Lockfile
LockFile="${BASEDIR}/${PROGNAME}..LOCK"

# Define the Hostname
HOSTName=`hostname -s`
# Logfile - all info will go in there.
LogFile="${BASEDIR}/${DATE}_${PROGNAME}.log"
CFGFILE="${BASEDIR}/cfgs/${PROG_PID}.cfg"

# Old configuration provided as argument.
# Initiating non interactive mode
OLDCONF=$1

# Configuration file
SHAREMOD="${BASEDIR}/mod/share.inc"

if [ -f $SHAREMOD ]
then
    . $SHAREMOD
else
    echo "*** ERROR: Unable to load shared functions. Abort."
    exit
fi

##########################################################################
# Actual script start
##########################################################################

# Prevent double execution
Lock $LockFile 1

# Guest SPAN Interface
EXPOSEDPORTS="8080 8443 81 80"

# Create Title
title "Docker CA TIM Image Builder"
# Log program version.
log "$LDATE `whoami`@`hostname` - ${PROGNAME}.sh version $VER"

# In case we don't have a configuration file directory, we need to
# create it.
if [ ! -d cfgs ]
then
    MSG="Creating configuration file directory failed"
    mkdir cfgs
    errlvl=$?
    errors
fi

if [ -f "$OLDCONF" ]
then
    source $OLDCONF
    log "Using $OLDCONF presets"

else

    echo "# $LDATE `whoami`@`hostname` - ${PROGNAME}.sh version $VER" > $CFGFILE
    echo "# TIM Docker Image builder configuration file" >> $CFGFILE
    echo 'EXPOSEDPORTS="8080 8443 81 80"' >> $CFGFILE
    
    
    # This script will configure then build the TIM Docker image and
    # provide scripts to start and access the container
    echo ">>> Which TIM version do you want to integrate into the image ?"
    echo ">>> Available Versions are listed below:"
    echo "==============================================================="
    count=0
    for dir in `ls -d tim* 2> /dev/null`
    do
	if [ -d $dir ]
	then
	    echo " * $dir "
	    let count=($count + 1)
	fi
    done
    # Check if we actually have a TIM
    if [ $count -lt 1 ]
    then
	echo "No TIM Software directory was detected."
	echo "Please download the TIM Software from the official"
	echo "Download location (support.ca.com) and unpack the"
	echo "TIM Files into a Directory named after the TIM Version"
	echo "\"tim10.1\" for the CA APM TIM 10.1 release"
	MSG="No TIM detected. Abort!"
	errlvl=1
	errors
    fi
    
    echo "==============================================================="
    echo -n ">>> Please copy & paste the version to use: "
    read TIMVER
    while [ ! -x ${TIMVER}/timInstall.bin ]
    do
	echo -n "*** [Invalid entry !]: "
	read TIMVER
    done
    log "Chosen TIM Version: $TIMVER"
    echo "TIMVER=$TIMVER" >> $CFGFILE
    
    
    echo
    echo "==============================================================="
    echo -n ">>> How many TIM Worker processes should be activated [4]: "
    read WORKERtmp
    RESP=$WORKERtmp
    WORKER=${WORKERtmp:=4}
    MSG="Worker processes set to: $WORKER"
    log $MSG
    if [ -z "$RESP" ]
    then
	echo "*** $MSG"
    fi
    echo "WORKER=$WORKER" >> $CFGFILE
    
    echo
    echo "==============================================================="
    echo -n ">>> How do you want to name the Image [caapm/$TIMVER]: "
    read NAMEtmp
    RESP=$NAMEtmp
    IMAGENAME=${NAMEtmp:=caapm/$TIMVER}
    MSG="Image Name set to: $IMAGENAME"
    log $MSG
    if [ -z "$RESP" ]
    then
	echo "*** $MSG"
    fi
    echo "IMAGENAME=$IMAGENAME" >> $CFGFILE
    
    echo
    echo "==============================================================="
    echo "!!! You need to accept the Eula in ${TIMVER}/ca-eula.en.txt !"
    echo -n ">>> Do you accept the Eula [y/n]: "
    read EULA
    
    if [ "$EULA" != "y" ]
    then
	MSG="Eula not accepted. Aborting !"
	errlvl=1
	errors
    fi
    log "Eula Accepted ? : $EULA"
    echo "EULA=$EULA" >> $CFGFILE
    
    
    echo
    echo "==============================================================="
    echo -n ">>> How do you want to name the Container [$TIMVER]: "
    read CONTAINERNAMEtmp
    RESP=$CONTAINERNAMEtmp
    CONTAINERNAME=${CONTAINERNAMEtmp:=$TIMVER}
    MSG="Container Name set to: $CONTAINERNAME"
    log $MSG
    if [ -z "$RESP" ]
    then
	echo "*** $MSG"
    fi
    echo "CONTAINERNAME=$CONTAINERNAME" >> $CFGFILE

    echo
    echo "==============================================================="
    echo "Container Network mode"
    echo "Depending on the location the container will be installed, it can"
    echo "be necessary to separate the container from the running host."
    echo " - \"host\": all networking from the running host will be made"
    echo "    available to the inside of the container."
    echo " - \"secured\": the container will get its own network, and one"
    echo "    dedicated network interface will be hijacked from the host"
    echo "    and into the container as SPAN port."
    echo -n ">>> Container network mode [host|secured]: "
    read NMODEtmp
    RESP=$NMODEtmp
    NMODE=${NMODEtmp:=secured}
    MSG="Network mode set to: $NMODE"
    log $MSG
    if [ -z "$RESP" ]
    then
	echo "*** $MSG"
    fi
    echo "NMODE=$NMODE" >> $CFGFILE

    
    if [ "$NMODE" == "secured" ]
    then
	# Secured Mode - we can configure the docker proxy setup.

	echo
	echo "==============================================================="
	echo ">>> Which Docker Host physical network interface will be used "
	echo ">>> as SPAN Port. Note that the interface will be made exclusively"
	echo ">>> available to the container running the $TIMVER, and will not"
	echo ">>> be usable by the Docker Host or any other container !"
	echo ">>> Use ifconfig to identify a suitable interface !"
	echo -n "Which interface to use: [No Default]: "
	read HOSTDEV
	log "Host Device: $HOSTDEV"
	echo "HOSTDEV=$HOSTDEV" >> $CFGFILE
	
	
	echo 
	echo "==============================================================="
	echo "   For the following, keep in mind that the TIM uses by default"
	echo "   port 80, 81 8080 and 443. These are the ports the TIM will"
	echo "   run inside the Docker container. If any of these ports is "
	echo "   already in useon the host system, it cannot be used by the"
	echo "   docker-proxy."
	
	echo
	echo "==============================================================="
	echo -n ">>> Which port do you want to map the HTTP Port 80 [80]: "
	read PORTHTTPtmp
	RESP=$PORTHTTPtmp
	PORTHTTP=${PORTHTTPtmp:=80}
	MSG="Port 80 mapped to $PORTHTTP"
	log $MSG
	if [ -z "$RESP" ]
	then
	    echo "*** $MSG"
	fi
	echo "PORTHTTP=$PORTHTTP" >> $CFGFILE
	
	
	echo
	echo "==============================================================="
	echo -n ">>> Which port do you want to map the HTTP Port 8080 [8080]: "
	read PORTHTTP8tmp
	RESP=$PORTHTTP8tmp
	PORTHTTP8=${PORTHTTP8tmp:=8080}
	MSG="Port 8080 mapped to $PORTHTTP8"
	log $MSG
	if [ -z "$RESP" ]
	then
	    echo "*** $MSG"
	fi
	echo "PORTHTTP8=$PORTHTTP8" >> $CFGFILE
	
	echo
	echo "==============================================================="
	echo -n ">>> Which port do you want to map the HTTP Port 81 [81]: "
	read PORTHTTP1tmp
	RESP=$PORTHTTP1tmp
	PORTHTTP1=${PORTHTTP1tmp:=81}
	MSG="Port 81 mapped to $PORTHTTP1"
	log $MSG
	if [ -z "$RESP" ]
	then
	    echo "*** $MSG"
	fi
	echo "PORTHTTP1=$PORTHTTP1" >> $CFGFILE
	
	echo
	echo "==============================================================="
	echo -n ">>> Which port do you want to map the HTTPS Port 443 [8443]: "
	read PORTHTTPStmp
	RESP=$PORTHTTPStmp
	PORTHTTPS=${PORTHTTPStmp:=8443}
	MSG="Port 8443 mapped to $PORTHTTPS"
	log $MSG
	if [ -z "$RESP" ]
	then
	    echo "*** $MSG"
	fi
	echo "PORTHTTPS=$PORTHTTPS" >> $CFGFILE

    else

	# Host Mode - we can configure the TIM Ports.

	echo 
	echo "==============================================================="
	echo "   For the following, keep in mind that the TIM uses by default"
	echo "   port 80, 81 8080 and 443. You now have the possibility to"
	echo "   change these ports. Make sure you reflect these ports in"
	echo "   the rest of the setup (EM/Collector/TESS etc.)"
	
	echo
	echo "==============================================================="
	echo -n ">>> Which port do you want to map the HTTP Port 80 [80]: "
	read PORTHTTPtmp
	RESP=$PORTHTTPtmp
	PORTHTTP=${PORTHTTPtmp:=80}
	MSG="Port 80 mapped to $PORTHTTP"
	log $MSG
	if [ -z "$RESP" ]
	then
	    echo "*** $MSG"
	fi
	echo "PORTHTTP=$PORTHTTP" >> $CFGFILE
	
	echo
	echo "==============================================================="
	echo -n ">>> Which port do you want to map the HTTP Port 81 [81]: "
	read PORTHTTP1tmp
	RESP=$PORTHTTP1tmp
	PORTHTTP1=${PORTHTTP1tmp:=81}
	MSG="Port 81 mapped to $PORTHTTP1"
	log $MSG
	if [ -z "$RESP" ]
	then
	    echo "*** $MSG"
	fi
	echo "PORTHTTP1=$PORTHTTP1" >> $CFGFILE
	
	echo
	echo "==============================================================="
	echo -n ">>> Which port do you want to map the HTTPS Port 443 [443]: "
	read PORTHTTPStmp
	RESP=$PORTHTTPStmp
	PORTHTTPS=${PORTHTTPStmp:=443}
	MSG="Port 443 mapped to $PORTHTTPS"
	log $MSG
	if [ -z "$RESP" ]
	then
	    echo "*** $MSG"
	fi
	echo "PORTHTTPS=$PORTHTTPS" >> $CFGFILE

    fi
	
    MSG="Moving Configuration file to new name failed"
    mv $CFGFILE cfgs/${CONTAINERNAME}.cfg
    errlvl=$?
    errors

fi


# Reconfigure the exposed Ports
EXPOSEDPORTS="$PORTHTTP $PORTHTTP1 $PORTHTTPS $PORTHTTP8"


echo 
echo ">>> Options for this Docker Image Build"
echo "==============================================================="
# Required VARS in Dockerfile
echo -e "TIM Version:\t\t$TIMVER"
echo -e "TIM Workers:\t\t$WORKER"
echo -e "Image name:\t\t$IMAGENAME"
echo -e "Exposed ports:\t\t$EXPOSEDPORTS"
echo -e "Network mode:\t\t$NMODE"
# Required VARS in start_tim.sh
echo -e "Container Name:\t\t$CONTAINERNAME"

if [ "$NMODE" == "secured" ]
then
    echo -e "Host SPAN Int.:\t\t$HOSTDEV"
    echo -e "Port 80 mapped to:\t$PORTHTTP"
    echo -e "Port 81 mapped to:\t$PORTHTTP1"
    echo -e "Port 8080 mapped to:\t$PORTHTTP8"
    echo -e "Port 8443 mapped to:\t$PORTHTTPS"
else
    echo -e "Port 80 changed to:\t$PORTHTTP"
    echo -e "Port 81 changed to:\t$PORTHTTP1"
    echo -e "Port 8443 changed to:\t$PORTHTTPS"
fi
    
echo
echo "==============================================================="
echo -n ">>> Proceed [y/n]: "
read PROCEED
if [ "$PROCEED" != "y" ]
then
    MSG="User aborted process !"
    errlvl=1
    errors
fi

if [ "$NMODE" == "secured" ]
then

    # ===================================
    echo -n "*** Generating CA_AUTOMATION file: "
    MSG="Creating CA_AUTOMATION file failed"
    echo "export PRIVATE_HTTPD=0" > CA_AUTOMATION
    errlvl=$?
    echo "export HTTP_PORT=80" >> CA_AUTOMATION
    echo "export HTTPS_PORT=8443" >> CA_AUTOMATION
    echo "export TIM_PORT=81" >> CA_AUTOMATION
    echo "export MOD_FIREWALL=0" >> CA_AUTOMATION
    echo "export INSTALL_TYPE=F" >> CA_AUTOMATION
    echo "export UPGRADE_KEEP_SETTINGS=0" >> CA_AUTOMATION
    echo " OK. "

    DOCKERFILE=Dockerfile.tpl.secure
    
else

    # ===================================
    echo -n "*** Generating CA_AUTOMATION file: "
    MSG="Creating CA_AUTOMATION file failed"
    echo "export PRIVATE_HTTPD=0" > CA_AUTOMATION
    errlvl=$?
    echo "export HTTP_PORT=$PORTHTTP" >> CA_AUTOMATION
    echo "export HTTPS_PORT=$PORTHTTPS" >> CA_AUTOMATION
    echo "export TIM_PORT=$PORTHTTP1" >> CA_AUTOMATION
    echo "export MOD_FIREWALL=0" >> CA_AUTOMATION
    echo "export INSTALL_TYPE=F" >> CA_AUTOMATION
    echo "export UPGRADE_KEEP_SETTINGS=0" >> CA_AUTOMATION
    echo " OK. "

    DOCKERFILE=Dockerfile.tpl.host
    
fi
  
# ===================================
echo -n "*** Generating Dockerfile: "
MSG="Creating Dockerfile failed"
sed -e "s/TIMVER/$TIMVER/g" mod/${DOCKERFILE} > Dockerfile.tmp
errlvl=$?
errors
sed -i "s/EXPOSEDPORTS/$EXPOSEDPORTS/g" Dockerfile.tmp
errlvl=$?
errors
sed -i "s/WORKER/$WORKER/g" Dockerfile.tmp
errlvl=$?
errors
sed -i "s/PORTHTTPS/$PORTHTTPS/g" Dockerfile.tmp
errlvl=$?
errors
sed -i "s/PORTHTTP/$PORTHTTP/g" Dockerfile.tmp
errlvl=$?
errors


# Special case for TIM 9.6.1 or 9.6.0
if [ `echo $TIMVER | grep -c "^tim9.6"` -gt 0 ]
then
    sed -i 's#RUN /root/timInstallRPM.sh#RUN /root/timInstallRPM.sh ; exit 0#g' Dockerfile.tmp
fi
mv Dockerfile.tmp Dockerfile
errlvl=$?
errors
echo " OK. "

# ===================================
if [ "$NMODE" == "secured" ]
then
    # Secured network mode
    echo -n "*** Creating Container start script: "
    MSG="Creating start_tim.sh script failed"
    sed -e s#CONTAINERNAME#$CONTAINERNAME#g mod/start_tim_secured.tpl > start_tim.tmp
    errlvl=$?
    errors
    sed -i s#IMAGENAME#$IMAGENAME#g start_tim.tmp
    errlvl=$?
    errors
    sed -i s#PORTHTTP1#$PORTHTTP1#g start_tim.tmp
    errlvl=$?
    errors
    sed -i s#PORTHTTP8#$PORTHTTP8#g start_tim.tmp
    errlvl=$?
    errors
    sed -i s#PORTHTTPS#$PORTHTTPS#g start_tim.tmp
    errlvl=$?
    errors
    sed -i s#PORTHTTP#$PORTHTTP#g start_tim.tmp
    errlvl=$?
    errors
    sed -i s#HOSTDEV#$HOSTDEV#g start_tim.tmp
    errlvl=$?
    errors
    mv start_tim.tmp start_${CONTAINERNAME}.sh
    errlvl=$?
    errors
    chmod 755 start_${CONTAINERNAME}.sh
    errlvl=$?
    errors
    echo " OK. "
else
    # Host network mode
    echo -n "*** Creating Container start script: "
    MSG="Creating start_tim.sh script failed"
    sed -e s#CONTAINERNAME#$CONTAINERNAME#g mod/start_tim_host.tpl > start_tim.tmp
    errlvl=$?
    errors
    sed -i s#IMAGENAME#$IMAGENAME#g start_tim.tmp
    errlvl=$?
    errors
    mv start_tim.tmp start_${CONTAINERNAME}.sh
    errlvl=$?
    errors
    chmod 755 start_${CONTAINERNAME}.sh
    errlvl=$?
    errors
    echo " OK. "

fi
# ===================================
echo -n "*** Creating Container access script: "
MSG="Creating tim_shell.sh script failed"
echo "docker exec -it $CONTAINERNAME /bin/bash" > ${CONTAINERNAME}_shell.sh
errlvl=$?
errors
chmod 755 ${CONTAINERNAME}_shell.sh
errlvl=$?
errors
echo " OK. "

echo
echo "==============================================================="
echo -n ">>> Create image [y/n]: "
read DOIMAGE
if [ "$DOIMAGE" != "y" ]
then
    MSG="User aborted process !"
    errlvl=1
    errors
fi
MSG="Creating Image $IMAGENAME"
log MSG
docker build -t="$IMAGENAME" .
errlvl=$?
errors


Unlock $LockFile
