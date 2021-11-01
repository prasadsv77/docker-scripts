#!/bin/bash

RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"
BLINK="\e[5m"
UNDERLINE="\e[4m"
dateAndTime=$(date +"%Y-%m-%d_%H.%M.%S")
ARG_COUNT=$#
ARGS_OPS=${1}

retrieve_metadata () {

    echo -e "${GREEN}$dateAndTime : CONTAINER LOGGER FORMAT is enabled. ${NOCOLOR}"
    CMI=''
    CID=''

    if [[ $POD_NAME && ${POD_NAME-x} ]]; then
        echo -e "${GREEN}POD_NAME Found"
        CMI+="${POD_NAME}_"
        val=`cat /proc/self/cgroup | grep ':name' | head -1 | cut -d '/' -f5 | cut -d '-' -f2 | cut -d '.' -f1`
        CID+="${val}"
    else
        echo -e "${RED}POD_NAME 'Not' Found"
    fi

    if [[ $POD_NAMESPACE && ${POD_NAMESPACE-x} ]]; then
        echo -e "${GREEN}POD_NAMESPACE Found"
        CMI+="${POD_NAMESPACE}_"
    else
        echo -e "${RED}POD_NAMESPACE 'Not' Found"
    fi

    if [[ $CONTAINER_NAME && ${CONTAINER_NAME-x} ]]; then
        echo -e "${GREEN}CONTAINER_NAME Found"
        CMI+="${CONTAINER_NAME}-"
    else
        echo -e "${RED}CONTAINER_NAME 'Not' Found"
    fi

    if [ -z "${CID// }" ];  then
        val=`cat /proc/self/cgroup | grep ':name' | head -1 | cut -d '/' -f3`
        CID+="${val}"
    fi

    CMI+="${CID}"
    echo -e "${RED}CONTAINER METADATA INFO - $CMI${NOCOLOR}"
    if [ "${CMI: -1}" == "_" ];  then CMI="${CMI%?}"; fi

    if [ ! -z "$CMI" ]; then
        export CONTAINER_METADATA_INFO=$CMI
    fi
}

_main () {
[[ $CONTAINER_LOG_FORMAT && ${CONTAINER_LOG_FORMAT-x} ]] && echo "CONTAINER LOGGER FORMAT is enabled." || (echo "CONTAINER LOGGER FORMAT is 'Not' enabled";)

if [ "$CONTAINER_LOG_FORMAT" == "true" ]; then
    retrieve_metadata
fi
}

set_log_path() {
  source $PPM_HOME_SCRIPTS/utils.sh
}

echo -e "${GREEN}$dateAndTime : Initiating the operations to fetch deployment metadata ${NOCOLOR}"
_main
set_log_path
