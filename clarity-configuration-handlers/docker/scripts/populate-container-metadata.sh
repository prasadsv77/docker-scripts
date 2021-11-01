#!/bin/bash

RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"
BLINK="\e[5m"
UNDERLINE="\e[4m"
dateAndTime=$(date +"%Y-%m-%d_%H.%M.%S")

retrieve_metadata () {

    echo
    echo -e "${GREEN}$dateAndTime : CONTAINER LOGGER FORMAT is enabled. ${NOCOLOR}"
    echo
    CMI=''
    CID=''

    if [[ $POD_NAME && ${POD_NAME-x} ]]; then
        echo -e "${GREEN}POD_NAME Found ${NOCOLOR}"
        CMI=$CMI"${POD_NAME}_"
        val=`cat /proc/self/cgroup | grep ':name' | head -1 | cut -d '/' -f5 | cut -d '-' -f2 | cut -d '.' -f1`
        CID=$CID"${val}"
    else
        echo -e "${RED}POD_NAME 'Not' Found ${NOCOLOR}"
    fi

    if [[ $POD_NAMESPACE && ${POD_NAMESPACE-x} ]]; then
        echo -e "${GREEN}POD_NAMESPACE Found ${NOCOLOR}"
        CMI=$CMI"${POD_NAMESPACE}_"
    else
        echo -e "${RED}POD_NAMESPACE 'Not' Found ${NOCOLOR}"
    fi

    if [[ $CONTAINER_NAME && ${CONTAINER_NAME-x} ]]; then
        echo -e "${GREEN}CONTAINER_NAME Found ${NOCOLOR}"
        CMI=$CMI"${CONTAINER_NAME}-"
    else
        echo -e "${RED}CONTAINER_NAME 'Not' Found ${NOCOLOR}"
    fi

    if [ -z "${CID// }" ];  then
        val=`cat /proc/self/cgroup | grep ':name' | head -1 | cut -d '/' -f3`
        CID=$CID"${val}"
    fi

    CMI=$CMI"${CID}"
    echo -e "${RED}Populated CONTAINER METADATA INFO - $CMI${NOCOLOR}"
    if [ "$CMI" == *_ ];  then
        CMI="${CMI%?}"
    fi

    if [ ! -z "$CMI" ]; then
        export CONTAINER_METADATA_INFO=$CMI
    fi
}


_main () {
[[ $CONTAINER_LOG_FORMAT && ${CONTAINER_LOG_FORMAT-x} ]] && echo "CONTAINER_LOG_FORMAT Found" || (echo "CONTAINER_LOG_FORMAT 'Not' Found";)

if [ "$CONTAINER_LOG_FORMAT" == "true" ]; then
    retrieve_metadata
fi
}

echo
echo -e "${GREEN}$dateAndTime : Initiating operations to fetch deployment metadata ${NOCOLOR}"
echo
_main
