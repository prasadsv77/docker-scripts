#!/usr/bin/env bash

dateAndTime=$(date +"%Y-%m-%d %H:%M:%S")
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;36m"
NOCOLOR="\033[0m"
BLINK="\e[5m"
UNDERLINE="\e[4m"
ORCHESTRATION_CLIENT_FOLDER="/opt/orchestration/client"
CLRT_DEPENDENCY_MGMT_CONFIGMAP="config-map-dependency-mgmt"
DIAGNOSTIC_FOLDER="/opt/ppm/logs/diagnostic"
#@ TODO: Generate log path with the container metadata
log_path=$PPM_HOME/logs/container/startup.log
if [[ ! -z $CONTAINER_METADATA_INFO ]]
then
  export log_path=$PPM_HOME/logs/container/$CONTAINER_METADATA_INFO-startup.log
fi

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

isRequired () {
  isRequired=$1
  if [[ ! -z $isRequired ]] && [[ $isRequired='true' ]]
  then
    #return 1;
    exit 1;
  fi
}

getProperty () {
   PROPERTY_FILE=$1
   PROP_KEY=$2
   PROP_VALUE=$(cat $PROPERTY_FILE | grep $PROP_KEY | cut -d'=' -f2)
   echo $PROP_VALUE
}

# Currently supporting overwrite the runtime with the release override files for GA releases
load_release_overrides () {
  # Load release overrides package in case of upgrade
  if [ "$PPM_INSTALL_TYPE" = "upgrade" ];
  then
    isValidReleaseOverrides
    _isValid=$?
    if test $_isValid -eq 0;
    then
      print "Copying files from $release_overrides_path to ${PPM_HOME}"
      admin cd load-release-overrides -Dinstall.dir=${PPM_HOME} -Dsource.dir="$release_overrides_path"
      CMD_RESULT=$?
      if [ $CMD_RESULT -ne 0 ]; then
        exit 1
      fi
    else
      print "Skip loading of release overrides due to no release override package available or missing files in the release folder."
    fi
  fi
}

insert_release_overrides_history () {
  if [ "$PPM_INSTALL_TYPE" = "upgrade" ];
  then
    isValidReleaseOverrides
    _isValid=$?
    if test $_isValid -eq 0;
    then
        print "insert the history entry for release overrides version"
        admin cd update-release-overrides-history
    fi
  fi
}

isValidReleaseOverrides () {
  # Loading version.properties file to fetch GA release
  source ${PPM_HOME}/.setup/version.properties
  if [[ -z $package ]]; # means GA release, package will be available only for patch releases
  then
    release_overrides_path="/opt/ppm/release-overrides/$release"
    if [ -d $release_overrides_path ] && [ ! -z "$(ls -A $release_overrides_path)" ];
    then
      #source ${PPM_HOME}/upgrade/maintenance-version.properties
      #if [ ! -z ${release.overrides.build} ];
      #then
      #  return 0;
      #fi
      # reset the permissions to rwx to the default(1010) user
      #chmod 700 -R /opt/ppm/release-overrides/$release
      return 0;
    fi
  fi
  return 1;
}

createDiagnosticFolder() {
    print "Creating diagnostic folder at $DIAGNOSTIC_FOLDER"
	mkdir -p $DIAGNOSTIC_FOLDER
}
getConfigMapKey (){
    FILE=$1
    OPS=$2
    _result=""
    if [[ $FILE = "install-db.sh" && $OPS = "db" ]]; then
        _result="CLRT_DB_IMPORT_STATUS_TOKEN"
    elif [[ $FILE = "install-db.sh" && $OPS = "dwh" ]]; then
        _result="CLRT_DWH_IMPORT_STATUS_TOKEN"
    elif [[ $FILE = "install-db.sh" && $OPS = "db_link" ]]; then
        _result="CLRT_DB_LINK_CREATE_STATUS_TOKEN"
    elif [ "$FILE" = "install-addins.sh" ]; then
        var=$(echo "$OPS" | /usr/bin/tr '[:lower:]' '[:upper:]')
        _result="CLRT_${var}_STATUS_TOKEN"
    elif [ "$FILE" = "install-plugins.sh" ]; then
        var=$(echo "$OPS" | /usr/bin/tr '[:lower:]' '[:upper:]')
        _result="CLRT_${var}_STATUS_TOKEN"
    elif [[ $FILE = "integrations.sh" && $OPS = "JSFT" ]]; then
        _result="CLRT_JSFT_INTEGRATION_TOKEN"
    elif [[ $FILE = "integrations.sh" && $OPS = "HDP" ]]; then
        _result="CLRT_HDP_INTEGRATION_TOKEN"
    elif [[ $FILE = "integrations.sh" && $OPS = "SSO" ]]; then
        _result="CLRT_SSO_INTEGRATION_TOKEN"
    elif [[ $FILE = "operations.sh" && $OPS = "operation_status" ]]; then
        _result="CLRT_OPERATIONS_STATUS_TOKEN"
    elif [[ $FILE = "operations.sh" ]]; then
        _result=$DEPENDENCY_MGMT_KEYS
    fi
    echo $_result
}

getMandatoryKeys () {

   keys=""
   if [ $PPM_SKIP_DB_IMPORT == "false" ]; then
      keys+="CLRT_DB_IMPORT_STATUS_TOKEN,CLRT_DWH_IMPORT_STATUS_TOKEN,CLRT_DB_LINK_CREATE_STATUS_TOKEN,"
   fi

   if [ ! -z "$PPM_ADDINS" ]; then
      keys+="CLRT_CSK_STATUS_TOKEN,"
   fi

   if [ "${keys: -1}" == "," ];  then keys="${keys%?}"; fi

   echo $keys
}
check_status_in_config_map (){
    _file_name=$1
    _check_status_item=$2
    # we dont want to run this check in vanilla docker env
    check_orchestration_env_availability
    _skip=$?
    # returning non-zero value (i.e. failure case), because this implies, DB import is not done
    if [ $_skip -gt 0 ]; then
        return 3
    fi

    print "# get Current File Name changed to  - '$_file_name'"
    PROP_NAME=$(getConfigMapKey $_file_name $_check_status_item)

    print "PROP_NAME $PROP_NAME"
    print "CLRT_DEPENDENCY_MGMT_CONFIGMAP : $CLRT_DEPENDENCY_MGMT_CONFIGMAP"
    print "# Executing Java Code to read from ConfigMap with above KEY and VALUE"
    print "-------------------------------------------------------------------"
    cd $ORCHESTRATION_CLIENT_FOLDER
    /usr/java/jdk/bin/java -Dlog4j.configuration=file:./log4j.properties -cp *:libs/* com.clarity.k8s.client.entrypoint.K8SClientLauncher \
                    --object-type config-maps \
                        --object-name $CLRT_DEPENDENCY_MGMT_CONFIGMAP \
                            --action read-process \
                                --namespace $POD_NAMESPACE \
                                    --keys $PROP_NAME
    _config_status=$?
    return $_config_status
}

update_status_in_config_map () {
    _file_name=$1
    _check_item=$2

    # we dont want to run this check in vanilla docker env
    check_orchestration_env_availability
    _skip=$?
    if [ $_skip -gt 0 ]; then
        return 0
    fi

    echo
    cd $ORCHESTRATION_CLIENT_FOLDER
    print "# update Current File Name changed to - '$_file_name'"
    print "# _check_item - '$_check_item'"
    PROP_NAME=$(getConfigMapKey $_file_name $_check_item)
    print "# Key name for DB installation - '$PROP_NAME'"
    if [ -n "$PROP_NAME" ]; then
        PROP_NAME_VAL=$(fetchInputValue $PROP_NAME)
    fi

    if [[ -z $PROP_NAME_VAL ]]
    then
       print "$PROP_NAME has no value in the User input config map."
       return 1
    fi

     createConfigMap $CLRT_DEPENDENCY_MGMT_CONFIGMAP
     _create_config_status=$?
     if test $_create_config_status -eq 0; then
         print "KEY = $PROP_NAME & VALUE = $PROP_NAME_VAL"
         print "KV pair found in the env variable. So updating ONLY configmap ($CLRT_DEPENDENCY_MGMT_CONFIGMAP) with new KV pair."
         updateKeyAvailableInConfigMap $CLRT_DEPENDENCY_MGMT_CONFIGMAP $PROP_NAME $PROP_NAME_VAL
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
    /usr/java/jdk/bin/java -Dlog4j.configuration=file:./log4j.properties -cp *:libs/* com.clarity.k8s.client.entrypoint.K8SClientLauncher \
                    --object-type config-maps \
                        --object-name $_OBJ_NAME \
                            --action update \
                                --namespace $POD_NAMESPACE \
                                    --key $_PROP_NAME --value $_PROP_VAL
    _update_status=$?
    print "-------------------------------------------------------------------"

    return $_update_status
}

createConfigMap () {
    _OBJ_NAME=$1
    print "Creating dependency config map."
    cd $ORCHESTRATION_CLIENT_FOLDER
    /usr/java/jdk/bin/java -Dlog4j.configuration=file:./log4j.properties -cp *:libs/* com.clarity.k8s.client.entrypoint.K8SClientLauncher \
                    --object-type config-maps \
                        --object-name $_OBJ_NAME \
                            --action create \
                                --namespace $POD_NAMESPACE
    _create_status=$?

    return $_create_status
}
check_orchestration_env_availability () {
    _orchestration_var=0
    if ! [[ $POD_NAMESPACE && ${POD_NAMESPACE-x} ]]; then
        _orchestration_var=$(($_orchestration_var+55))
    fi
     if ! [[ $KUBERNETES_SERVICE_HOST && ${KUBERNETES_SERVICE_HOST-x} ]]; then
        _orchestration_var=$(($_orchestration_var+77))
    fi
     return $_orchestration_var
}

setDefaultSymlinks() {
  ln -sf $PPM_HOME/customconfig/properties.xml $PPM_HOME/config/properties.xml
  ln -sf $PPM_HOME/customconfig/logger.xml $PPM_HOME/config/logger.xml
  ln -sf $PPM_HOME/customconfig/components.xml $PPM_HOME/config/components.xml
}

loadDefaultConfigurationFiles() {
  cp -n $PPM_HOME/.setup/templates/config/logger.xml $PPM_HOME/customconfig/logger.xml
  cp -f $PPM_HOME/.setup/templates/config/tenants.xml $PPM_HOME/config/tenants.xml
  cp -n $PPM_HOME/.setup/templates/config/components.xml $PPM_HOME/customconfig/components.xml
}

loadDefaultConfigurations() {
  # Hide file scan in systemoptions page
  print "$PPM_HOME/bin/admin toggle-feature DISPLAY_FILE_SCANNING_OPTION 0"
  $PPM_HOME/bin/admin toggle-feature DISPLAY_FILE_SCANNING_OPTION 0

  if  [[ ! -z $PPM_ENABLE_FILE_SCAN ]]
  then
    print "Enable file scan: $PPM_ENABLE_FILE_SCAN"
    if [[ "$PPM_ENABLE_FILE_SCAN" = "false" ]];
    then
      # Disable the scanning enable option
      print "admin cd update_cmn_option -Dcode=DMS_SCANNING_ENABLE -DuserName=admin -Dvalue=0"
      admin cd update_cmn_option -Dcode=DMS_SCANNING_ENABLE -DuserName=admin -Dvalue=0
    else
      # Enable the scanning enable option
      print "admin cd update_cmn_option -Dcode=DMS_SCANNING_ENABLE -DuserName=admin -Dvalue=1"
      admin cd update_cmn_option -Dcode=DMS_SCANNING_ENABLE -DuserName=admin -Dvalue=1
    fi

    _update_file_scan_status=$?
    if test $_update_file_scan_status -ne 0; then
        print "Failed to update the file scanning option"
        return 1
    fi
  fi
}

checkMandatoryOperation() {
  print "checking mandatory or not for $PROP_NAME"
  if [[ $DEPENDENCY_MGMT_KEYS =~ $PROP_NAME ]]
  then
     return 0
  else
    return 1
  fi
}

populateDBCustomTableSpaces() {
    PPM_DB_USERS_LARGE_TS=$(echo 'cat //properties/databaseServer/@largeTables' | xmllint --shell $PPM_HOME/config/properties.xml | awk -F'[="]' '!/>/{print $(NF-1)}')
    PPM_DB_USERS_SMALL_TS=$(echo 'cat //properties/databaseServer/@smallTables' | xmllint --shell $PPM_HOME/config/properties.xml | awk -F'[="]' '!/>/{print $(NF-1)}')
    PPM_DB_INDX_LARGE_TS=$(echo 'cat //properties/databaseServer/@largeIndex' | xmllint --shell $PPM_HOME/config/properties.xml | awk -F'[="]' '!/>/{print $(NF-1)}')
    PPM_DB_INDX_SMALL_TS=$(echo 'cat //properties/databaseServer/@smallIndex' | xmllint --shell $PPM_HOME/config/properties.xml | awk -F'[="]' '!/>/{print $(NF-1)}')
}

populateDWHCustomTableSpaces() {
    PPM_DWH_DATA_DIM_TS=$(echo 'cat //properties/dwhDatabaseServer/@dimensionTables' | xmllint --shell $PPM_HOME/config/properties.xml | awk -F'[="]' '!/>/{print $(NF-1)}')
    PPM_DWH_DATA_FACT_TS=$(echo 'cat //properties/dwhDatabaseServer/@factTables' | xmllint --shell $PPM_HOME/config/properties.xml | awk -F'[="]' '!/>/{print $(NF-1)}')
    PPM_DWH_INDX_DIM_TS=$(echo 'cat //properties/dwhDatabaseServer/@dimensionIndex' | xmllint --shell $PPM_HOME/config/properties.xml | awk -F'[="]' '!/>/{print $(NF-1)}')
    PPM_DWH_INDX_FACT_TS=$(echo 'cat //properties/dwhDatabaseServer/@factIndex' | xmllint --shell $PPM_HOME/config/properties.xml | awk -F'[="]' '!/>/{print $(NF-1)}')
}

populateTimeZone() {
    echo $TIME_ZONE > /etc/timezone
}


updateOperationStatusToken() {
   createConfigMap $CLRT_DEPENDENCY_MGMT_CONFIGMAP
   print "config map: $CLRT_DEPENDENCY_MGMT_CONFIGMAP, key: CLRT_OPERATIONS_STATUS_TOKEN, value: $CLRT_OPERATIONS_STATUS_TOKEN"
   updateKeyAvailableInConfigMap $CLRT_DEPENDENCY_MGMT_CONFIGMAP "CLRT_OPERATIONS_STATUS_TOKEN" $CLRT_OPERATIONS_STATUS_TOKEN
   _final_config_update_status=$?
   if test $_final_config_update_status -eq 0; then
        print "Updated config map with final status" "GREEN"
        if test $_pod_status -ne 0; then
                    exit 1
        fi
   else
        print "Update to config map with final status has failed" "RED"
        exit 1
   fi
}

enable_hdp ( ) {
    print "Enabling HDP...."
    $PPM_HOME/bin/admin cd setup_hdp -Ddwhsysusername=$PPM_DB_PRIVILEGED_USER -Ddwhsyspassword=$PPM_DB_PRIVILEGED_USER_PWD -Ddwhreadonlyrolename=$HDP_DWH_RO_ROLE  -Ddwhreadonlyusername=$HDP_DWH_RO_USERNAME -Ddwhreadonlyuserpwd=$HDP_DWH_RO_USER_PASSWORD -Dhdp.server.url=$HDP_SERVER_URL -Dhdp.dataSourceName=$HDP_DATASOURCENAME -Dhdp.userName=$HDP_USERNAME -Dhdp.admin.user=$HDP_PRIVILEGED_USER -Dhdp.admin.password=$HDP_PRIVILEGED_USER_PWD
    hdp_integration_status=$?
    return $hdp_integration_status
}

create_extension () {
  print "creating extension...."
  $PPM_HOME/bin/admin cd create_extension -Dsysusername=$PPM_DB_PRIVILEGED_USER -Dsyspassword=$PPM_DB_PRIVILEGED_USER_PWD
  extension_status=$?
  return $extension_status
}

create_db_link () {
  print "creating db link..."
  $PPM_HOME/bin/admin db create-db-link
  db_link_status=$?
  return $db_link_status
}

create_loop_back_db_link () {
  print "creating loopback db link...."
  $PPM_HOME/bin/admin db create-db-link -Dtype=app -Dsysusername=$PPM_DB_PRIVILEGED_USER -Dsyspassword=$PPM_DB_PRIVILEGED_USER_PWD
  loop_back_db_link_status=$?
  return $loop_back_db_link_status
}

update_jaspersoft_params () {
   print "Running update jasperParameters to update the profile attributes with latest clarity details"
   $PPM_HOME/bin/admin update jasperParameters
   jsft_update_params_status=$?
  return $jsft_update_params_status
}

run_syncPPMContext () {
  print "Running syncPPMContext to update the profile attributes with latest clarity details and reset domains"
  $PPM_HOME/bin/admin jaspersoft syncPPMContext -userName $JS_PRIVILEGED_USER -password $JS_PRIVILEGED_USER_PWD
  jsft_syncPPMContext_status=$?
  return $jsft_syncPPMContext_status
}

reset_hdp () {
  print "Reset HDP..."
  $PPM_HOME/bin/admin cd reset_hdp -Dhdp.server.url=$HDP_SERVER_URL -Dhdp.dataSourceName=$HDP_DATASOURCENAME -Dhdp.userName=$HDP_USERNAME -Dhdp.admin.user=$HDP_PRIVILEGED_USER -Dhdp.admin.password=$HDP_PRIVILEGED_USER_PWD
  hdp_reset_status=$?
  return $hdp_reset_status
}

check_status_exit_on_error () {
  _status=$1
  _success_message=$2
  _failure_message=$3
  if test $_status -eq 0; then
    print "$_success_message"
  else
    print "$_failure_message" "RED"
    exit 1
  fi
}