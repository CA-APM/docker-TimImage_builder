#
# Internal ID & Revision:
# $Id: share.inc,v 1.4 2012/10/16 13:36:02 jmertin Exp $
# $Revision: 1.4 $
#
# File Name - Location variable:
#% Argument: share
#%
#% Short description:
#% Stores default functions used by scripts
#
# -------------------------------------------------------------
#
###############################################################################
# Log function - very small
log() {

    # Be verbose
    ! $VERBOSE || echo "> ${PROGNAME} $*"

    # no logger found, no syslog capabilities
    if [ $DOLOGGER ]
        then
	if [ -x $LOGGER ]
	then
            ! $SYSLOG || $LOGGER -t "${PROGNAME}" "$*"
	fi
    fi

    # Write it all out to a Log-File.
    echo "> ${PROGNAME} $*" >> $LogFile

} # log function.

#
##############################################################################
#
# Little Usage help.
usage() {
    echo
    echo -e >&2 "Usage:\t${PROGNAME}.sh <action>  <option> "
    echo -e >&2 "\tThis script applies some modifications to a RedHat ES 4 Update 8"
    echo -e >&2 "\tto make harden the OS."
    echo -e >&2
    echo
} # function usage

# Little Usage help.
Version() {
    echo -e >&2 "Program ${PROGNAME}.sh version $VER"
    echo -e >&2 " RCS$Id: share.inc,v 1.4 2012/10/16 13:36:02 jmertin Exp $"
    echo -e >&2 " (c) J. Mertin <joerg.mertin@ca.com>"
    echo -e >&2
    echo -e >&2 " This Program peforms a OS Hardening depending on configuration"
    echo -e >&2 " settings found in the backup-Directory"
    echo -e >&2
}
#
##############################################################################
#
errors() {
#DOC: The errors Function is called to control the exit status.
#
: ${errlvl:=9}
: ${MSG:="No Error message - Probably user interruption"}
if [ $errlvl -gt 0 ] ;
    then
    if [ $errlvl = 15 ] ;
    then
	$VERBOSE && echo -e "WARNING: $MSG"
        log "WARNING: $MSG"
    else
        ##Usage
        echo -e "\a"
        echo "FATAL:  An error occured in \"${PROGNAME}(${FUNCTION})\". Bailing out..."
        echo -e "ERRMSG: $MSG"
        echo
        log "FATAL: $MSG"
        Unlock $LockFile
        exit $errlvl
    fi
fi
} # errors Function
#
#
##############################################################################
#
# Lockfile Generation
Lock() {
# Lockfile to create
tolock="$1"
Action="$2"
#
# Lock file if lockfile does not exist.
if [ -s $tolock ]
then
    # If we have provided a second Var, set Exit status using  it.
    if [ ! -n "$Action" ]
    then
	# Oops, we  found a lockfile. Loop while checking if still exists.
	while [ -s $tolock ]
	do
	    sleep 5 ;
	done
	MSG="Creating lockfile $tolock failed after 5 secs"
	# write PID into Lock-File.
	echo $$ > $tolock
	errlvl=$?
	errors
    else
	Pid="`cat $tolock`"
	Exists="`ps auxw | grep \" $Pid \" | grep -c $PROGNAME`"
	if [ $Exists = 1 ]
	then
	    MSG="\"$PROGNAME\" already running. Exiting..."
	    errlvl=$Action
	    errors
	else
	    MSG="Found stale lockfile... Removing it..."
	    rm -f $tolock
	    errlvl=$?
	    errors
	    MSG="Creating lockfile $tolock failed"
	    echo $$ > $tolock
	    errlvl=$?
	    errors
	fi
    fi
else
    # Lock it
    MSG="Creating lockfile $tolock failed"
    echo $$ > $tolock
    errlvl=$?
    errors
fi
} # Lock
#
##############################################################################
#
Unlock(){
# Name of Lockfile to unlock
unlock="$1"
# Unlock the file.
if [ -s $unlock ]
then
    PID=$$
    if [ "`cat $unlock`" != "$PID" ]
    then
        # Lock it
	echo -e "WARNING: Wrong lock-file PID. Probably a race-condition happened...\n"
    else
        # Removing Lockfile
        rm -f $unlock
    fi
fi
#
} # Unlock
#

##############################################################################
#  Formatting functions
##############################################################################
space () {
    MSG="Add space to $LogFile"
    echo "" >> $LogFile
    errlvl=$?
    errors
}

##############################################################################
title () {
    # Set to
    line=""
    lg=`echo $* | wc -c`
    let length=($lg + 4)
    while [ $length -lt 80 ]; 
    do
	line="${line}="
	let length=($length + 1)
    done

    space
    space
    echo "===============================================================================" >> $LogFile

    MSG="Add title: $* to $LogFile"
    echo "== $* $line" >> $LogFile
    errlvl=$?
    errors
    echo "===============================================================================" >> $LogFile

}
##############################################################################
separator () {
    MSG="Add separator to $LogFile"
    echo "================================================================================"  >> $LogFile
    errlvl=$?
    errors

}
##############################################################################
entry () {

    # Set to
    line=""
    lg=`echo $* | wc -c`
    let length=($lg + 8)
    while [ $length -lt 80 ]; 
    do
	line="${line}="
	let length=($length + 1)
    done

    # Add a space
    space
    MSG="Add entry: $* to $LogFile"
    echo "=== $* !  $line"  >> $LogFile
    errlvl=$?
    errors
}

##############################################################################