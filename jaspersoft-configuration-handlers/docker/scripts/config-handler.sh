#!/bin/bash

APPLICATION_TYPE=$1
OPERATION_TYPE=$2
FORMAT_TYPE=$3
dateAndTime=$(date +"%Y-%m-%d_%H.%M.%S")
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;36m"
NOCOLOR="\033[0m"
BLINK="\e[5m"
UNDERLINE="\e[4m"
SLEEP_SECONDS=10
STATUS_FLAG_DONE=999
startTime=`date +%s`
PROP_NAME="CLRT_UPDATE_CONFIG_STATUS_TOKEN"
ORCHESTRATION_CLIENT_FOLDER="/opt/orchestration/client"
CONFIG_UPDATE_DEPENDENCY_MGMT_CONFIGMAP="config-map-dependency-mgmt"
operation="validate"
if [[ -z $INIT_CONTAINER_LIFE_SPAN ]]
then
    timeSpan=180
else
    timeSpan=$INIT_CONTAINER_LIFE_SPAN
fi
endTime=$(($timeSpan + $startTime))
log_path=/opt/logs/config-handler.log
if [ $APPLICATION_TYPE != "hdp"  ]; then
source "/opt/config-scripts/populate-container-metadata.sh"
fi
source "/opt/config-scripts/migration.sh"
set_log_file_path () {
    echo "CONTAINER_LOG_FORMAT: $CONTAINER_LOG_FORMAT"
    echo "CONTAINER_METADATA_INFO: $CONTAINER_METADATA_INFO"
    if [[ ! -z $CONTAINER_METADATA_INFO ]]
    then
        echo "changing file path to $CONTAINER_METADATA_INFO"
      export log_path=/opt/logs/$CONTAINER_METADATA_INFO-config-handler.log
    fi
}
print () {
  message=$1
  color=$2
  if [[ -z $2 ]]
  then
    echo "$dateAndTime $message" | tee -a $log_path
  else
      echo -e "$dateAndTime $(fetchInputValue $color)$message${NOCOLOR}" | tee -a $log_path
  fi
}

fetchInputValue() {
  eval "input=\${$1}"
  echo "$input"
}

load_configs ( ) {
    print "Loading configuration files..."
    APPLICATION=$1
    CONFIG_DIR=""
    if [ $APPLICATION = "jaspersoft" ]; then
       CONFIG_DIR="/opt/jsft/input/configs"
    elif [ $APPLICATION = "hdp"  ]; then
       CONFIG_DIR="/opt/hdp/input/configs"
    elif [ $APPLICATION = "clarity"  ]; then
       CONFIG_DIR="/opt/ppm/input/configs"
    fi

    #Read properties from optional configuration files
    for f in $CONFIG_DIR/*
    do
      if [ -f "$f" ]; then
        print "Sourcing configuration file $f" "GREEN"
        set -a
        source $f
        set +a
      fi
    done
}

check_orchestration_env_availability () {
    _orchestration_var=0
    if [[ $POD_NAMESPACE && ${POD_NAMESPACE-x} ]]; then
        print "POD_NAMESPACE env variable found.....!!!!"
    else
        return 55
    fi

    if [[ $KUBERNETES_SERVICE_HOST && ${KUBERNETES_SERVICE_HOST-x} ]]; then
        print "KUBERNETES_SERVICE_HOST environment variable found....!!!"
    else
        return 77;
    fi

    return $_orchestration_var
}

update_status_in_config_map () {
    # we dont want to run this check in vanilla docker env
    check_orchestration_env_availability
    _skip=$?
    if [[ $_skip -gt 0 ]]
     then
       return 0
    fi
    PROP_NAME_VAL=$(fetchInputValue $PROP_NAME)

    if [[ -z $PROP_NAME_VAL ]]
    then
       print "$PROP_NAME has no value in the User input config map."
       return 1
    fi

    cd $ORCHESTRATION_CLIENT_FOLDER

    createConfigMap $CONFIG_UPDATE_DEPENDENCY_MGMT_CONFIGMAP
     _create_config_status=$?
     if test $_create_config_status -eq 0; then
        print "KEY = $PROP_NAME & VALUE = $PROP_NAME_VAL"
        print "KV pair found in the env variable. So updating ONLY configmap ($CONFIG_UPDATE_DEPENDENCY_MGMT_CONFIGMAP) with new KV pair."
        updateKeyAvailableInConfigMap $CONFIG_UPDATE_DEPENDENCY_MGMT_CONFIGMAP $PROP_NAME $PROP_NAME_VAL
        _cmd_exec=$?
     else
        print "Failed to create dependency config map."
        return 1
     fi

    return $_cmd_exec
}

updateKeyAvailableInConfigMap (){

    _OBJ_NAME=$1
    _PROP_NAME=$2
    _PROP_VAL=$3
    echo
    print "# Executing Java Code to update ConfigMap with above KEY and VALUE"
    print "-------------------------------------------------------------------"
    cd $ORCHESTRATION_CLIENT_FOLDER
    java -Dlog4j.configuration=file:./log4j.properties -Duser.timezone=$TIME_ZONE -cp *:libs/* com.clarity.k8s.client.entrypoint.K8SClientLauncher \
                    --object-type config-maps \
                        --object-name $_OBJ_NAME \
                            --action update \
                                --namespace $POD_NAMESPACE \
                                    --key $PROP_NAME --value $_PROP_VAL

    _update_status=$?
    print "-------------------------------------------------------------------"

    return $_update_status
}

update_config_map_with_status () {
    # If operation is update, then only config map should be updated for dependency management
    # For populate and validate we dont need any token update.
    if [ $OPERATION_TYPE = "update" ]; then
        PROP_NAME="CLRT_UPDATE_CONFIG_STATUS_TOKEN"
        update_status_in_config_map
        _config_map_update_status=$?
        if [ $_config_map_update_status = 0 ];
        then
           print "config map is updated."
        else
           print "config $OPERATION_TYPE" has failed.
        fi
    fi

}


createConfigMap () {
    _OBJ_NAME=$1
    print "Creating dependency config map."
    cd $ORCHESTRATION_CLIENT_FOLDER
    java -Dlog4j.configuration=file:./log4j.properties -Duser.timezone=$TIME_ZONE -cp *:libs/* com.clarity.k8s.client.entrypoint.K8SClientLauncher \
                    --object-type config-maps \
                        --object-name $_OBJ_NAME \
                            --action create \
                                --namespace $POD_NAMESPACE
    _create_status=$?

    return $_create_status
}

_check_properties_file_exists () {
  if [ -f "$PPM_HOME/config/properties.xml" ]
  then
    print "Configuration file properties.xml already exists..."
    return 0
  else
    print "Configuration file properties.xml does not exist..."
    return 1
  fi
}

_set_operation () {
    if [ $OPERATION_TYPE = "migrate" ]
    then
        operation="validate"
    else
        operation=$OPERATION_TYPE
    fi
}

_main () {
    set_log_file_path
    if [ $OPERATION_TYPE = "populate" ]
    then
      _check_properties_file_exists
      _file_exists=$?
      if [ $_file_exists = 0 ]
      then
        print "Properties.xml is already present. Hence updating it."
        operation="update"
      fi
    fi
    load_configs $APPLICATION_TYPE
    _set_operation
    print "Making java call to $operation for $APPLICATION_TYPE"
    java -Duser.timezone=$TIME_ZONE -cp "*:libs/*" com.broadcom.clarity.validator.entrypoint.ConfigurationHandler --apps $APPLICATION_TYPE --response-type $FORMAT_TYPE --operation $operation 1>/tmp/config_handler.txt 2>&1
    CONFIG_HANDLER_STATUS=$?
    cat /tmp/config_handler.txt | tee -a $log_path
    > /tmp/config_handler.txt
    if [ $OPERATION_TYPE = "migrate" ]
    then
      _validate_required_folders
      _folders_exists=$?
      if [[ $_folders_exists = 0 && $CONFIG_HANDLER_STATUS = 0 ]]
      then
        print "All the required files/folders are present."
        return 0
      else
        print "Some of the required files/folders are not available." "RED"
        return 1
      fi
    fi
    return $CONFIG_HANDLER_STATUS
}


echo
echo "Started performing validation in  INIT-Containers."
echo
_main

STATUS=$?

if test $STATUS -eq 0; then
   print "Operation Successful."
   print "Exiting with status 0."
   exit 0
else
   print "Operation failed."
   print "Exiting with status 1."
   exit 1
fi

#if [[ $OPERATION_TYPE = "populate" ]] || [[ $OPERATION_TYPE = "validate" ]]; then
#    if [[ $STATUS != 0 ]]; then
#      print "Exiting with status 1"
#      exit 1
#    else
#      print "Exiting with status 0"
#      exit 0
#    fi
#else
    # Running something in foreground, otherwise the container will stop in config update case
#	while true
#	do
#   		tail -f /dev/null & wait ${!}
#	done
#fi
