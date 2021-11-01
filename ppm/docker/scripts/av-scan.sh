#!/bin/bash

#=============================================================================
# NAME:		FILESCAN.SH
#=============================================================================
# Params:	$1 = full path of file to be scanned (supplied by PPM)
#=============================================================================
LOG_FILE=/opt/ppm/logs/$CONTAINER_METADATA_INFO-filescan.log

#=============================================================================
# VARIABLES
#=============================================================================
CLAMAV_HOME=/home/default/clamav
CLAMAV_LIB=$CLAMAV_HOME/lib64
ANTI_VIRUS_DB_DIR=/home/default/anti-virus-database/data

CLAMAV_DAEMON_SCAN_TOOL=$CLAMAV_HOME/bin/clamdscan
CLAMAV_DAEMON_SCAN_TOOL_CONF=/home/default/clamdscan-conf/clamdscan.conf
FILE_TO_SCAN=$1

echo ;echo
# setting clamav libs to user 1010
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CLAMAV_LIB

#CLAMAV_SCAN_TOOL=${CLAMAV_HOME}/bin/clamscan --database $ANTI_VIRUS_DB_DIR


#=============================================================================
# FUNCTIONS
#=============================================================================

function do_exit {
	echo ===========================
	echo $(date +'%x %X')
	echo Ending with exit code: $1

	exit $1
}


#=============================================================================
# MAIN
#=============================================================================
echo Beginning command line scan...
echo $(date +'%x %X')
echo ===========================

if [ "-$@-" == "--" ]
then
        # exit if no file specified
    echo ERROR: No command line parameters supplied!
    do_exit 1
else
        #echo Parameter supplied: \'$FILE_TO_SCAN\'
        myfilesize=$(wc -c "$FILE_TO_SCAN" | awk '{print $1/(1024*1024)}')
        echo File supplied: \'$FILE_TO_SCAN\' with size: \'$myfilesize\'MB
        echo
fi

startTime=$(( $(date '+%s%N') / 1000000));
$CLAMAV_DAEMON_SCAN_TOOL --config-file=$CLAMAV_DAEMON_SCAN_TOOL_CONF -v $FILE_TO_SCAN
EXEC_RESULT=$?
endTime=$(( $(date '+%s%N') / 1000000));

#Subtract endTime from startTime to get the total execution time
totalTime=$(($endTime-$startTime));

echo "Filescan finished after $(( $totalTime/1000 )) seconds";
#$CLAM_SCAN_CMD $FILE_TO_SCAN

if [ $EXEC_RESULT -ne 0 ]
then
	# clamav returned anything other than 0, exit and return 1
	echo *** Virus found! ***
    do_exit 1
fi

# exit successfully
echo NO virus found!

do_exit 0