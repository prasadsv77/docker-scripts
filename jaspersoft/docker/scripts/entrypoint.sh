#!/bin/bash


dateAndTime=$(date +"%Y-%m-%d_%H.%M.%S")
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;36m"
NOCOLOR="\033[0m"
BLINK="\e[5m"
UNDERLINE="\e[4m"
ARG_COUNT=$#
ARGS_OPS=${1}
ARGS_JSFT_APP_NAME=${2}
DEF_MASTER_PROP=default_master.properties
SMPL_ORCL_MASTER_PROP=oracle_template.properties
SMPL_MSSQL_MASTER_PROP=sqlserver_template.properties
SMPL_POSTGRESQL_MASTER_PROP=postgresql_template.properties
JSFT_DEF_WEBAPP_NAME=reportservice
JSFT_MOD_WEBAPP_NAME=reportservice
METADATA_SCRIPT="$SCRIPTS_HOME/populate-container-metadata.sh"
TOMCAT_LOGGING_PROP="/opt/tomcat/conf/logging.properties"
TOMCAT_SERVER_XML="/opt/tomcat/conf/server.xml"
JSFT_LOGGING_PROP="/opt/tomcat/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/log4j2.properties"
#added the spring context xml for transaction log with container metadata
SPRING_APPC_VDS_XML="/opt/tomcat/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/applicationContext-virtual-data-source.xml"
DB_SETUP_VALIDATION_TARGET_TEMPLATE=$SCRIPTS_HOME/validation_template.xml
DB_SETUP_VALIDATION_TARGET=${JASPERSOFT_LOCATION}/buildomatic/bin/validation.xml

DB_SETUP_VALIDATION_QUERY_ORACLE_TEMPLATE=$SCRIPTS_HOME/db_oracle.xml
DB_SETUP_VALIDATION_QUERY_ORACLE=${JASPERSOFT_LOCATION}/buildomatic/conf_source/db/oracle/db.xml

DB_SETUP_VALIDATION_QUERY_SQL_SERVER_TEMPLATE=$SCRIPTS_HOME/db_sql_server.xml
DB_SETUP_VALIDATION_QUERY_SQL_SERVER=${JASPERSOFT_LOCATION}/buildomatic/conf_source/db/sqlserver/db.xml

DB_SETUP_VALIDATION_QUERY_POSTGRESQL_TEMPLATE=$SCRIPTS_HOME/db_postgresql.xml
DB_SETUP_VALIDATION_QUERY_POSTGRESQL=${JASPERSOFT_LOCATION}/buildomatic/conf_source/db/postgresql/db.xml


ORCHESTRATION_CLIENT_FOLDER="/opt/orchestration/client"
CLRT_JSFT_FRESH_DB_STATUS_TOKEN_KEY="CLRT_JSFT_FRESH_DB_STATUS_TOKEN"
CLRT_JSFT_PATCH_DB_STATUS_TOKEN_KEY="CLRT_JSFT_PATCH_DB_STATUS_TOKEN"
CLRT_JSFT_UPGRADE_DB_STATUS_TOKEN_KEY="CLRT_JSFT_UPGRADE_DB_STATUS_TOKEN"
CONFIGMAP_NAME="config-map-dependency-mgmt"
JSFT_DIR="/opt/jsft"
CONTAINER_INSTALLER_KS_DIR="$JSFT_DIR/keystore/installer"
JS_CONFIG_PROPERTIES_FILE="js.config.properties"
log_path=/opt/logs/startup.log

set_log_file_path () {
    echo "CONTAINER_LOG_FORMAT: $CONTAINER_LOG_FORMAT"
    echo "CONTAINER_METADATA_INFO: $CONTAINER_METADATA_INFO"
    if [[ ! -z $CONTAINER_METADATA_INFO ]]
    then
        echo "changing file path to $CONTAINER_METADATA_INFO"
      export log_path="/opt/logs/${CONTAINER_METADATA_INFO}startup.log"
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

populateTimeZone () {
    echo $TIME_ZONE > /etc/timezone
}

validate_args () {

    if [ "$ARG_COUNT" -lt 1 ]; then
        print "Illegal number of parameters passed ...." "RED"
        exit 1
    fi

    if [ -z "$ARGS_JSFT_APP_NAME" ]; then
        print "Jaspersoft Server web app name is unchanged. Default name - $JSFT_MOD_WEBAPP_NAME"
        echo
    else
        JSFT_MOD_WEBAPP_NAME=$ARGS_JSFT_APP_NAME
        print "Jaspersoft Server web app name is changed to - $JSFT_MOD_WEBAPP_NAME"
        echo
    fi

    print "Validation of input arguments wrt env variables completed!!!" "GREEN"
}


copy_validation_template_file () {
    if [ -f "$DB_SETUP_VALIDATION_TARGET_TEMPLATE" ]; then
        cp -f $DB_SETUP_VALIDATION_TARGET_TEMPLATE $DB_SETUP_VALIDATION_TARGET
    fi
    if [ -f "$DB_SETUP_VALIDATION_QUERY_ORACLE_TEMPLATE" ]; then
        cp -f $DB_SETUP_VALIDATION_QUERY_ORACLE_TEMPLATE $DB_SETUP_VALIDATION_QUERY_ORACLE
    fi
    if [ -f "$DB_SETUP_VALIDATION_QUERY_SQL_SERVER_TEMPLATE" ]; then
        cp -f $DB_SETUP_VALIDATION_QUERY_SQL_SERVER_TEMPLATE $DB_SETUP_VALIDATION_QUERY_SQL_SERVER
    fi
    if [ -f "$DB_SETUP_VALIDATION_QUERY_POSTGRESQL_TEMPLATE" ]; then
        cp -f $DB_SETUP_VALIDATION_QUERY_POSTGRESQL_TEMPLATE $DB_SETUP_VALIDATION_QUERY_POSTGRESQL
    fi
	print "copied template files"
}

load_configs ( ) {
    print "Loading configuration files..."
    #Read properties from optional configuration files
    for f in $JSFT_CONFIG_DIR/*
    do
      if [ -f "$f" ]; then
        print "Sourcing configuration file $f" "GREEN"
        source $f
      fi
    done
}

main_ () {
    set_orchestration_metadata
    #populate user-input timezone
    populateTimeZone
    load_configs
    copy_validation_template_file
    validate_args
    generate_default_master_properties
    #INSTALL_DB|DEPLOY_JSFT
    IFS='|' read -a operations <<< "$ARGS_OPS"


    for i in "${operations[@]}"
    do
        case "$i" in
          INSTALL_JSFT_DB) echo
               init_db
               _init_db_status=$?
               return $_init_db_status
               ;;
          DEPLOY_JSFT_APP) echo
               print "ActiveMQ is cluster?? $IS_ACTIVEMQ_MASTER_SLAVE"
               print "Jaspersoft nodes required??  $JS_DEPLOYMENT_ENV_TYPE"
               echo
               if [ "$IS_ACTIVEMQ_MASTER_SLAVE" == "true" -a "$JS_DEPLOYMENT_ENV_TYPE" == "multi-node" ]; then
                    validate_active_mq_cluster_connection
               elif [ "$IS_ACTIVEMQ_MASTER_SLAVE" == "false"  -a "$JS_DEPLOYMENT_ENV_TYPE" == "multi-node" ]; then
                    validate_active_mq_connection
               else
                    print "Skipping ActiveMQ broker service validation!!!"
               fi
               deploy_web_app
               ;;
	      VALIDATE_DB) echo
               validate_jasperserver_db_setup "true"
               _db_setup_status=$?
               return $_db_setup_status
               ;;
          *) echo; echo "Invalid Operation name - ' $i ' passed as an argument." && exit 1;
        esac
    done
}

_cal_runtime_ () {

    runtime=$(($2-$1))
    echo
    print "Total runtime for funtion '$3' is = $runtime seconds"
    echo
}

generate_default_master_properties() {

    start=`date +%s`
    [[ $JS_DB_TYPE && ${JS_DB_TYPE-x} ]] && (echo; print "JS_DB_TYPE environment variable found - $JS_DB_TYPE"; echo) || (print "JS_DB_TYPE 'Not' Found";return 1)

    if [ "$JS_DB_TYPE" == "oracle" ]; then
        cp -f $SCRIPTS_HOME/$SMPL_ORCL_MASTER_PROP $SCRIPTS_HOME/$DEF_MASTER_PROP

        [[ $JS_DB_ORCL_TYPE && ${JS_DB_ORCL_TYPE-x} ]] && (echo; print "JS_DB_ORCL_TYPE environment variable found - $JS_DB_ORCL_TYPE";echo) || (print "JS_DB_ORCL_TYPE 'Not' Found";return 1)

        sed -i -e "s|PH_JS_DB_ORCL_TYPE|$JS_DB_ORCL_TYPE|g" $SCRIPTS_HOME/$DEF_MASTER_PROP

        if [ $JS_DB_ORCL_TYPE == "standalone" ]; then  echo "sid=$JS_ORCL_SID_SRVNAME" >> $SCRIPTS_HOME/$DEF_MASTER_PROP  ;  else  print "Unable to setup 'SID' for Oracle. Oracle Type should be a 'STANDALONE' "; fi

        if [ $JS_DB_ORCL_TYPE == "cluster" ]; then  echo "serviceName=$JS_ORCL_SID_SRVNAME" >> $SCRIPTS_HOME/$DEF_MASTER_PROP ; else print "Unable to setup 'SERVICENAME' for Oracle. Oracle Type should be a 'CLUSTER' "; fi

    fi


    if [ "$JS_DB_TYPE" == "sqlserver" ]; then
        cp -f $SCRIPTS_HOME/$SMPL_MSSQL_MASTER_PROP $SCRIPTS_HOME/$DEF_MASTER_PROP

        [[ $JS_IS_NAMED_INSTANCE && ${JS_IS_NAMED_INSTANCE-x} ]] && (echo; print "JS_IS_NAMED_INSTANCE environment variable found - $JS_IS_NAMED_INSTANCE";echo) || (print "JS_IS_NAMED_INSTANCE 'Not' Found";return 1)

        sed -i -e "s|PH_JS_IS_NAMED_INSTANCE|$JS_IS_NAMED_INSTANCE|g" $SCRIPTS_HOME/$DEF_MASTER_PROP

        if [ $JS_IS_NAMED_INSTANCE == "true" ]; then  echo "dbInstance=$JS_DB_SQLSERVER_INSTANCE_NAME" >> $SCRIPTS_HOME/$DEF_MASTER_PROP  ;  else  print "Unable to setup 'DB Instance Name' for SQLServer."; fi

        if [ $JS_IS_NAMED_INSTANCE == "false" ]; then  echo "dbPort=$JS_DB_PORT" >> $SCRIPTS_HOME/$DEF_MASTER_PROP ; else print "Unable to setup 'DB Port' for SQLServer.  "; fi

        [[ $JS_DB_NAME && ${JS_DB_NAME-x} ]] && (echo; print "JS_DB_NAME environment variable found - $JS_DB_NAME";echo; echo "js.dbName=$JS_DB_NAME" >> $SCRIPTS_HOME/$DEF_MASTER_PROP) || (print "JS_DB_NAME 'Not' Found";return 1)
    fi

    if [ "$JS_DB_TYPE" == "postgresql" ]; then
        cp -f $SCRIPTS_HOME/$SMPL_POSTGRESQL_MASTER_PROP $SCRIPTS_HOME/$DEF_MASTER_PROP

        [[ $JS_DB_NAME && ${JS_DB_NAME-x} ]] && (echo; print "JS_DB_NAME environment variable found - $JS_DB_NAME";echo; echo "js.dbName=$JS_DB_NAME" >> $SCRIPTS_HOME/$DEF_MASTER_PROP) || (print "JS_DB_NAME 'Not' Found";return 1)
    fi

    sed -i -e "s|PH_JS_DEPLOY_ENV|$JS_DPY_ENV|g" $SCRIPTS_HOME/$DEF_MASTER_PROP
    sed -i -e "s|PH_JS_DEPLOY_COMPLIANCE|$JS_DPY_ENV_COMPLIANCE|g" $SCRIPTS_HOME/$DEF_MASTER_PROP
    sed -i -e "s|PH_JS_LOG_HOST|$JS_LOG_HOST|g" $SCRIPTS_HOME/$DEF_MASTER_PROP
    sed -i -e "s|PH_JS_ISOLATE_SCHEDULER|$JS_ISOLATE_SCHEDULER|g" $SCRIPTS_HOME/$DEF_MASTER_PROP
    sed -i -e "s|PH_JS_SCHEDULER_INS|$JS_SCH_INS|g" $SCRIPTS_HOME/$DEF_MASTER_PROP
    sed -i -e "s|PH_JS_INSTALL_METHOD|$JS_INSTALL_METHOD|g" $SCRIPTS_HOME/$DEF_MASTER_PROP
    sed -i -e "s|PH_JS_INSTALL_MODE|$JS_INSTALL_MODE|g" $SCRIPTS_HOME/$DEF_MASTER_PROP
    sed -i -e "s|PH_JS_INSTALL_MODE_TYPE|$JS_INSTALL_MODE_TYPE|g" $SCRIPTS_HOME/$DEF_MASTER_PROP

    if [ "$JS_INSTALL_METHOD" == "upgrade" ]; then
      if [ -z "$JS_UPGRADE_FROM_VERSION" ]; then
          echo "overrideDefaultUpgradeFromVersion=7.1.3" >> $SCRIPTS_HOME/$DEF_MASTER_PROP
      else
        echo "overrideDefaultUpgradeFromVersion=$JS_UPGRADE_FROM_VERSION" >> $SCRIPTS_HOME/$DEF_MASTER_PROP
      fi
    fi

    sed -i -e "s|PH_JS_DB_HOST|$JS_DB_HOST|g" $SCRIPTS_HOME/$DEF_MASTER_PROP
    sed -i -e "s|PH_JS_DB_UNAME|$JS_DB_UNAME|g" $SCRIPTS_HOME/$DEF_MASTER_PROP
    sed -i -e "s|PH_JS_DB_PWD|$JS_DB_PWD|g" $SCRIPTS_HOME/$DEF_MASTER_PROP
    sed -i -e "s|PH_JS_SYSDB_UNAME|$JS_SYSDB_UNAME|g" $SCRIPTS_HOME/$DEF_MASTER_PROP
    sed -i -e "s|PH_JS_SYSDB_PWD|$JS_SYSDB_PWD|g" $SCRIPTS_HOME/$DEF_MASTER_PROP
    sed -i -e "s|PH_DB_PORT|$JS_DB_PORT|g" $SCRIPTS_HOME/$DEF_MASTER_PROP


    if [ "$JS_MAIL_SETUP" == "true" ]; then
        echo "quartz.mail.sender.host=$JS_MAIL_HOST" >> $SCRIPTS_HOME/$DEF_MASTER_PROP
        echo "quartz.mail.sender.port=$JS_MAIL_PORT" >> $SCRIPTS_HOME/$DEF_MASTER_PROP
        echo "quartz.mail.sender.protocol=$JS_MAIL_PROTOCOL" >> $SCRIPTS_HOME/$DEF_MASTER_PROP
        echo "quartz.mail.sender.username=$JS_MAIL_SENDER_UNAME" >> $SCRIPTS_HOME/$DEF_MASTER_PROP
        echo "quartz.mail.sender.password=$JS_MAIL_SENDER_PWD" >> $SCRIPTS_HOME/$DEF_MASTER_PROP
        echo "quartz.mail.sender.from=$JS_MAIL_SENDER_FROM" >> $SCRIPTS_HOME/$DEF_MASTER_PROP
    fi

    sed -i -e "s|PH_WEB_DEPLOYMENT_URL|$JS_LB_URL_DEPLOYMENT|g" $SCRIPTS_HOME/$DEF_MASTER_PROP

    cp -f $SCRIPTS_HOME/$DEF_MASTER_PROP ${JASPERSOFT_LOCATION}/buildomatic/$DEF_MASTER_PROP

    end=`date +%s`
    _cal_runtime_ $start $end "generate_default_master_properties"
}

setup_jasperserver_db() {
    start=`date +%s`
    # check if patch.properties is present then set the flag to true
    if [ -f "${JASPERSOFT_LOCATION}/buildomatic/patch-info.properties" ]; then
        _is_patch_installer="true"
    fi

    # if the image has patch then based on js_install_method flags, depedency tokens will be set
    if [ "$_is_patch_installer" == "true" ]; then
        # if js_install_method is "new" then based on js_install_only_patch flags, depedency tokens will be set
        if [ "$JS_INSTALL_METHOD" == "new" ]; then
            _status_key="$CLRT_JSFT_FRESH_DB_STATUS_TOKEN_KEY"
            DEPENDENCY_MGMT_KEYS="$CLRT_JSFT_FRESH_DB_STATUS_TOKEN_KEY,$CLRT_JSFT_PATCH_DB_STATUS_TOKEN_KEY"
        # if js_install_method is not "new" then depedency token will be upgrade token.
        fi
        if [ "$JS_INSTALL_METHOD" == "upgrade" ]; then
            _status_key=$CLRT_JSFT_UPGRADE_DB_STATUS_TOKEN_KEY
            DEPENDENCY_MGMT_KEYS=$CLRT_JSFT_UPGRADE_DB_STATUS_TOKEN_KEY,$CLRT_JSFT_PATCH_DB_STATUS_TOKEN_KEY
        fi
    else
        # If the image does not have any patch then depedency check is for fresh db and upgrade tokens correspondingly.
        if [ "$JS_INSTALL_METHOD" == "new" ]; then
            _status_key=$CLRT_JSFT_FRESH_DB_STATUS_TOKEN_KEY
            DEPENDENCY_MGMT_KEYS=$CLRT_JSFT_FRESH_DB_STATUS_TOKEN_KEY
        fi
        if [ "$JS_INSTALL_METHOD" == "upgrade" ]; then
            _status_key=$CLRT_JSFT_UPGRADE_DB_STATUS_TOKEN_KEY
            DEPENDENCY_MGMT_KEYS=$CLRT_JSFT_UPGRADE_DB_STATUS_TOKEN_KEY
        fi
    fi

    print "checking config map before starting import..."
    check_status_in_config_map $_status_key
    _check_cm_for_repeatability=$?
    if test $_check_cm_for_repeatability -eq 0; then
        print "Checked config map. DB operations are already done." "GREEN"
        _fresh_db_status=0
    else
        echo
        print "Checked config map. DB operations are not done yet."
        print "Verifying the database connection..."
        #Sometimes when the db-check failed, the ant target is returning true; and writing the error message 'NO_DB_FOUND' to stdout. So we need to verify failure of both the cases i.e. result of ant target and the output in text file create_db_err.txt
        cd ${JASPERSOFT_LOCATION}/buildomatic
        if ./js-ant -DfailOnDBNotExists=true -DfailOnConnectionError=true -DdatabaseNotExistsMessage=NO_DB_FOUND do-install-upgrade-test -S -q 1>/tmp/create_db_err.txt 2>&1
        then
            dbCheckSuccess=true
        else
            dbCheckSuccess=false
        fi
        print database check success flag: $dbCheckSuccess
        cat /tmp/create_db_err.txt |& tee -a $log_path

        if [ "$dbCheckSuccess" = "true" ]; then
              echo
              print "DB connection is available..."
              if [ "$JS_INSTALL_METHOD" == "new" ]; then
                     if [ "$JS_SKIP_DB_IMPORT" == "false" ]; then
                        print "JS_SKIP_DB_IMPORT = $JS_SKIP_DB_IMPORT" "GREEN"

                        #check if tables already exists
                        # We will not log this as in this case build failure is our success
                        validate_jasperserver_db_setup "false"
                        _validate_db=$?
                        if [ $_validate_db -eq 0 ]; then
                          print "DB tables already exists. Hence, stopping JS DB Import." "RED"
                          exit 101
                        fi

                        print "Creating fresh and clean Jaspersoft DB"

                        cd ${JASPERSOFT_LOCATION}/buildomatic
                        ./js-ant init-js-db-pro import-minimal-pro jaas-post-install 1>/tmp/import_log.txt 2>&1
                        _db_import_status=$?

                        cat /tmp/import_log.txt |& tee -a $log_path
                        > /tmp/import_log.txt
                     else
                        _db_import_status=0
                     fi
                    
                     if test $_db_import_status -eq 0; then
                            print "Verifying the database setup ..."

                            # validate if db import is successful
                            validate_jasperserver_db_setup "true"
                            _db_verification_status=$?

                            # to update configmap with FRESH DB INSTALL's success or failure message
                            if [ $_db_verification_status -eq 0 ]; then

                                print "updating config map for key $_status_key ..."
                                update_status_in_config_map $_status_key
                                _config_map_update_status=$?

                                if test $_config_map_update_status -eq 0; then
                                    print "updated config map for key $_status_key ..."
                                    _fresh_db_status=0
                                else
                                    print "config map update failed." "RED"
                                    return 1
                                fi
                            else
                                print "DB verification failed" "RED"
                                return 1
                            fi
                    else
                        print "DB import failed" "RED"
                        return 1
                    fi
              fi

              if [ "$JS_INSTALL_METHOD" = "upgrade" ]; then

                #check if tables already exists for upgrade
                # We will not log this as in this case
                validate_jasperserver_db_setup "false"
                _validate_db=$?
                if [ $_validate_db -ne 0 ]; then
                  print "DB tables does not  exists. Hence, stopping JS DB Upgrade." "RED"
                  exit 101
                fi

                print "Upgrading Jaspersoft existing DB....."
                cd ${JASPERSOFT_LOCATION}/buildomatic

                ./js-ant upgrade-js-pro-db-minimal -DpromptUpgrade=false 1>/tmp/upgrade_log.txt 2>&1
                _db_upgrade_status=$?
                cat /tmp/upgrade_log.txt |& tee -a $log_path
                > /tmp/upgrade_log.txt
                if [ $_db_upgrade_status -eq 0 ]; then
                    ./js-ant jaas-post-upgrade 1>/tmp/post_upgrade_log.txt 2>&1
                    _db_import_status=$?
                else
                    _db_import_status=-100
                fi

                cat /tmp/post_upgrade_log.txt |& tee -a $log_path
                > /tmp/post_upgrade_log.txt

                # to update configmap with UPGRADE's success or failure message
                if test $_db_import_status -eq 0; then
                    update_status_in_config_map $_status_key
                    _config_map_update_status=$?
                    if test $_config_map_update_status -eq 0; then
                        print "updated config map for key $_status_key ..."
                        _fresh_db_status=0
                    else
                        print "config map update failed." "RED"
                        return 1
                    fi
                else
                    print "Same DB upgrade verification failed" "RED"
                    return 1
                fi

              fi

        else
            print "DB connection check failed" "RED"
            return 1
        fi

    fi

    if test $_fresh_db_status -eq 0; then
        if [ "$_is_patch_installer" == "true" ]; then
          print "calling patch operations..."
            apply_patch
        else
            return 0
        fi
    fi

    end=`date +%s`
    _cal_runtime_ $start $end "setup_jasperserver_db"

}

cp_legacy_keystore_files () {
    count_keystore_files=`ls -1a $CONTAINER_INSTALLER_KS_DIR/.jrsks* 2>/dev/null | wc -l`
    print "No. of keystore files found in dir - $CONTAINER_INSTALLER_KS_DIR are : $count_keystore_files"
    # copy 7.1.3 keystore legacy files for 
    if [ $count_keystore_files -lt 2 ]
    then 
        unzip $JSFT_DIR/installer-ks-file.zip -d $CONTAINER_INSTALLER_KS_DIR

    fi

    count_keystore_files_recheck=`ls -1a $CONTAINER_INSTALLER_KS_DIR/.jrsks* 2>/dev/null | wc -l`
    if test $count_keystore_files_recheck -eq 2; then
        return 0
    else
        return 1
    fi
}

apply_patch () {
    check_status_in_config_map $CLRT_JSFT_PATCH_DB_STATUS_TOKEN_KEY
    _check_cm_for_repeatability=$?
    if test $_check_cm_for_repeatability -eq 0; then
        print "Checked config map. DB patch operations are already done." "GREEN"
        return 0
    else
      print "Checked config map. DB patch operations are not yet done."
       cd ${JASPERSOFT_LOCATION}/buildomatic
       ./js-ant jaas-dbpatch-setup 1>/tmp/patch_log.txt 2>&1
       _db_patch_status=$?

       cat /tmp/patch_log.txt |& tee -a $log_path
       > /tmp/patch_log.txt

       # to update configmap with DB PATCH INSTALL's success or failure message
       if [ $_db_patch_status -eq 0 ]; then
           print "updating config map for key $CLRT_JSFT_PATCH_DB_STATUS_TOKEN_KEY ..."
           update_status_in_config_map $CLRT_JSFT_PATCH_DB_STATUS_TOKEN_KEY
           _config_map_update_status=$?

           if test $_config_map_update_status -eq 0; then
             print "updated config map for key $CLRT_JSFT_PATCH_DB_STATUS_TOKEN_KEY ..."
          else
              print "config map update failed." "RED"
              return 1
          fi
       else
          print "DB patch failed" "RED"
          return 1
       fi
   fi
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

update_status_in_config_map () {

    # we dont want to run this check in vanilla docker env
    check_orchestration_env_availability
    _skip=$?
    if [ $_skip -gt 0 ]; then
        return 0
    fi


    _db_status_key=$1


    cd $ORCHESTRATION_CLIENT_FOLDER

    _db_status_val=$(fetchInputValue $_db_status_key)

    if [[ -z $_db_status_val ]]
    then
       print "$_db_status_key has no value in the User input config map."
       return 1
    fi

    createConfigMap $CONFIGMAP_NAME
    _create_config_status=$?
    if test $_create_config_status -eq 0; then
        /usr/java/jdk/bin/java -Dlog4j.configuration=file:./log4j.properties -cp *:libs/* com.clarity.k8s.client.entrypoint.K8SClientLauncher \
                        --object-type config-maps \
                            --object-name $CONFIGMAP_NAME \
                                --action update \
                                    --namespace $POD_NAMESPACE \
                                        --key $_db_status_key --value $_db_status_val 1>/tmp/check_config.txt 2>&1
     else
         print "Failed to create dependency config map."
         return 1
     fi

    _update_status=$?

    cat /tmp/check_config.txt |& tee -a $log_path
    > /tmp/check_config.txt
    return $_update_status
}

check_status_in_config_map () {

    # we dont want to run this check in vanilla docker env
    check_orchestration_env_availability
    _skip=$?
    # returning non-zero value (i.e. failure case), because this implies, DB import is not done
    if [ $_skip -gt 0 ]; then
        return 3
    fi

    _status_keys=$1

    cd $ORCHESTRATION_CLIENT_FOLDER

    /usr/java/jdk/bin/java -Dlog4j.configuration=file:./log4j.properties -cp *:libs/* com.clarity.k8s.client.entrypoint.K8SClientLauncher \
                    --object-type config-maps \
                        --object-name $CONFIGMAP_NAME \
                            --action read-process \
                                --namespace $POD_NAMESPACE \
                                    --keys $_status_keys 1>/tmp/check_config.txt 2>&1
    _db_import_status=$?

    cat /tmp/check_config.txt |& tee -a $log_path
    > /tmp/check_config.txt
    return $_db_import_status
}

validate_jasperserver_db_setup() {

    required_logging=$1
    #Sometimes when the db-check failed, the ant target is returning true; and writing the error message 'NO_DB_FOUND' to stdout. So we need to verify failure of both the cases i.e. result of ant target and the output in text file create_db_err.txt
    cd ${JASPERSOFT_LOCATION}/buildomatic
    if ./js-ant do-db-setup-test -S -q 1>/tmp/db_verification.txt 2>&1
    then
        _ver_status=0
    else
        _ver_status=1
    fi

    #logging the status only when required
    if [ "$required_logging" = "true" ]; then
    cat /tmp/db_verification.txt |& tee -a $log_path
    > /tmp/db_verification.txt
    fi
    return $_ver_status
}

setup_cache_masterslave_replication() {

   providerUrlString=$( get_url_based_on_replica_count );
   echo "Constructed provider URI is ${providerUrlString}";
   start=`date +%s`
   if [ "$JS_EHCACHE_CONFIG" = "jms" -a "$JS_DEPLOYMENT_ENV_TYPE" = "multi-node" ]; then
       print "Valid to connect to ActiveMQ message connector ports... $providerUrlString" "GREEN"
       print "Configuring Jaspersoft server for cache replication over JMS with ActiveMQ"

       sed -e "s/tcp:\/\/localhost:61616/${providerUrlString}/g" <$JASPERSOFT_LOCATION/overlay/ehcache/jms/WEB-INF/ehcache_hibernate.xml >$CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/ehcache_hibernate.xml
       sed -i -e "/JRSActiveMQInitialContextFactory/,/propertySeparator/{s/,$/~/g}" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/ehcache_hibernate.xml
       sed -i -e "/[ \t]topicBindingName/{n;s/,/~/}" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/ehcache_hibernate.xml

       sed -e "s/tcp:\/\/localhost:61616/${providerUrlString}/g" <$JASPERSOFT_LOCATION/overlay/ehcache/jms/WEB-INF/ehcache_hibernate.xml >$CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/classes/ehcache_hibernate.xml
       sed -i -e "/JRSActiveMQInitialContextFactory/,/propertySeparator/{s/,$/~/g}" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/classes/ehcache_hibernate.xml
       sed -i -e "/[ \t]topicBindingName/{n;s/,/~/}" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/classes/ehcache_hibernate.xml

       sed -e "s/tcp:\/\/localhost:61616/${providerUrlString}/g" <$JASPERSOFT_LOCATION/overlay/ehcache/jms/WEB-INF/ehcache.xml >$CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/ehcache.xml
       sed -i -e "/JRSActiveMQInitialContextFactory/,/propertySeparator/{s/,$/~/g}" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/ehcache.xml
       sed -i -e "/[ \t]topicBindingName/{n;s/,/~/}" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/ehcache.xml

   fi

    end=`date +%s`
    _cal_runtime_ $start $end "setup_cache_masterslave_replication"

}

get_url_based_on_replica_count(){
    providerUrl=$(a=0; while [[ $a -lt $ACTIVEMQ_REPLICA_COUNT ]]; do echo -n "tcp:\/\/activemq-${a}.activemq-broker-headless-service:61616",;a=`expr $a + 1`; done| sed 's/,$//');
    echo "failover:(${providerUrl})";
}


setup_cache_replication() {

   start=`date +%s`
   if [ "$JS_EHCACHE_CONFIG" = "jms" -a "$JS_DEPLOYMENT_ENV_TYPE" = "multi-node" ]; then

       if [[ $ACTIVEMQ_PROVIDER_HOST_PORT && ${ACTIVEMQ_PROVIDER_HOST_PORT-x} ]]; then
            print "Valid to connect to ActiveMQ message connector port... $ACTIVEMQ_PROVIDER_HOST_PORT" "GREEN"
            print "Configuring Jaspersoft server for cache replication over JMS with ActiveMQ"
            sed -e "s/tcp:\/\/localhost:61616/tcp:\/\/${ACTIVEMQ_PROVIDER_HOST_PORT}/g"  <$JASPERSOFT_LOCATION/overlay/ehcache/jms/WEB-INF/ehcache.xml >$CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/ehcache.xml
            sed -e "s/tcp:\/\/localhost:61616/tcp:\/\/${ACTIVEMQ_PROVIDER_HOST_PORT}/g"  <$JASPERSOFT_LOCATION/overlay/ehcache/jms/WEB-INF/ehcache_hibernate.xml >$CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/ehcache_hibernate.xml
            sed -e "s/tcp:\/\/localhost:61616/tcp:\/\/${ACTIVEMQ_PROVIDER_HOST_PORT}/g"  <$JASPERSOFT_LOCATION/overlay/ehcache/jms/WEB-INF/ehcache_hibernate.xml >$CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/classes/ehcache_hibernate.xml
        else
            print "Invalid connection to ActiveMQ message connector port..." "RED"
            exit 55
        fi
   fi

    end=`date +%s`
    _cal_runtime_ $start $end "setup_cache_replication"

}


configure_keystore() {

  if [[ ! -f "$CONTAINER_INSTALLER_KS_DIR/.jrsks" && ! -f "$CONTAINER_INSTALLER_KS_DIR/.jrsksp" ]]; then
    if [ "$JS_INSTALL_METHOD" == "new" ]; then
      echo "keystore files are not present. Hence generating."
         cd ${JASPERSOFT_LOCATION}/buildomatic
          ./js-ant --noconfig -nouserlib -f ../install.xml checkOS createKeystoreLinux 1>/tmp/keystore_log.txt 2>&1
          _keystore_status=$?

          cat /tmp/keystore_log.txt |& tee -a $log_path
          > /tmp/keystore_log.txt

          if [ $_keystore_status -gt 0 ]; then
              echo "Failed to generate keystore."
              exit 1
          fi
    fi

    if [ "$JS_INSTALL_METHOD" == "upgrade" ]; then
      echo "keystore files are not present for upgrade. Copying legacy keystores."
         cd ${JASPERSOFT_LOCATION}/buildomatic
          cp_legacy_keystore_files
          cp_keystore_done=$?

          if [ $cp_keystore_done -eq 0 ]; then
            echo "copied legacy keystores."
          else
            print "Upgrade failed due to keystore issues in the dir - $CONTAINER_INSTALLER_KS_DIR" "RED"
            exit 1
          fi

    fi
  fi
}


init_db() {
  configure_keystore
  # Run-only db creation targets.
  setup_jasperserver_db
  _db_init_status=$?

     check_status_in_config_map $DEPENDENCY_MGMT_KEYS
        _final_status=$?

        if test $_final_status -eq 0; then
           print "All mandatory operations are completed.Updating the status in config map"
           update_status_in_config_map "CLRT_OPERATIONS_STATUS_TOKEN"
           _final_config_update_status=$?
           if test $_final_status -eq 0; then
                print "Updated config map with final status" "GREEN"
           else
                print "Update to config map with final status has failed" "RED"
           fi
        else
           print "Some of the mandatory operations are not completed." "RED"
        fi
  return $_db_init_status
}

deploy_web_app () {
  start=`date +%s`
  echo
  print "Installing Jaspersoft Report Server Web-application in Tomcat"
  echo

  print "JSFT_MOD_WEBAPP_NAME :: $JSFT_MOD_WEBAPP_NAME"
  if [ $JSFT_DEF_WEBAPP_NAME != $JSFT_MOD_WEBAPP_NAME ]; then
    cd $CATALINA_HOME/webapps
    mv $JSFT_DEF_WEBAPP_NAME $JSFT_MOD_WEBAPP_NAME
  fi

  cd ${JASPERSOFT_LOCATION}/buildomatic
  ./js-ant \
    init-source-paths \
    set-pro-webapp-name \
    deploy-webapp-datasource-configs \
    deploy-jdbc-jar \
    -DwarTargetDir=$CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME |& tee -a $log_path

  cd ${JASPERSOFT_LOCATION}
  ant -f install.xml checkDefaultValues configure |& tee -a $log_path

  if [ "$JS_DEPLOYMENT_ENV_TYPE" = "multi-node" ]; then
      echo
      print "Setting up Jaspersoft cache replication over ActiveMQ"
      if [ "$IS_ACTIVEMQ_MASTER_SLAVE" = "true" ]; then 
         setup_cache_masterslave_replication
      else
         setup_cache_replication
      fi
  fi

  cd $CATALINA_HOME

  echo
  end=`date +%s`
   _cal_runtime_ $start $end "deploy_web_app"
   set_jvm_args
   add_container_metadata_as_java_args
   modify_log_filename
   set_quartz_base_properties
   set_quartz_properties
   set_quartz_governor_jasperreports_properties
   set_chrome_properties
   copy_container_overlay
   run_jasperserver
}

copy_container_overlay () {
  if [ -d $SCRIPTS_HOME/overlay ]; then
    print "Overlay folder exists"
    if test -n "$(find $SCRIPTS_HOME/overlay -maxdepth 0 -empty)" ; then
        print "Overlay folder is empty"
    else
      print "Overlay folder is not empty"
      cp -rfv $SCRIPTS_HOME/overlay/* $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME
    fi
  fi
}

set_quartz_base_properties () {
  QUARTZ_BASE_PROPS_FILE="js.quartz.base.properties"
  if [ ! -z "$JS_SCHEDULER_JOB_THREAD_COUNT" ]; then
    echo "updating threadcount...."
    sed -i -e "/org.quartz.threadPool.threadCount=/ s/=.*/=$JS_SCHEDULER_JOB_THREAD_COUNT/" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/$QUARTZ_BASE_PROPS_FILE
  fi
  if [ ! -z "$JS_SCHEDULER_JOB_THREAD_PRIORITY" ]; then
    echo "updating threadPriority...."
    sed -i -e "/org.quartz.threadPool.threadPriority=/ s/=.*/=$JS_SCHEDULER_JOB_THREAD_PRIORITY/" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/$QUARTZ_BASE_PROPS_FILE
  fi
  if [ ! -z "$JS_SCHEDULER_JOB_MISFIRE_THRESHOLD" ]; then
    echo "updating misfireThreshold...."
    sed -i -e "/org.quartz.jobStore.misfireThreshold=/ s/=.*/=$JS_SCHEDULER_JOB_MISFIRE_THRESHOLD/" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/$QUARTZ_BASE_PROPS_FILE
  fi
}

set_quartz_properties () {
  QUARTZ_PROPS_FILE="js.quartz.properties"
  if [ ! -z "$JS_SCHEDULER_SIMPLEJOB_MISFIRE_POLICY" ]; then
    echo "updating singlesimplejob...."
    sed -i -e "/report.quartz.misfirepolicy.singlesimplejob=/ s/=.*/=$JS_SCHEDULER_SIMPLEJOB_MISFIRE_POLICY/" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/$QUARTZ_PROPS_FILE
  fi
  if [ ! -z "$JS_SCHEDULER_REPEATINGJOB_MISFIRE_POLICY" ]; then
    echo "updating repeatingsimplejob...."
    sed -i -e "/report.quartz.misfirepolicy.repeatingsimplejob=/ s/=.*/=$JS_SCHEDULER_REPEATINGJOB_MISFIRE_POLICY/" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/$QUARTZ_PROPS_FILE
  fi
  if [ ! -z "$JS_SCHEDULER_CALENDARJOB_MISFIRE_POLICY" ]; then
    echo "updating calendarjob...."
    sed -i -e "/report.quartz.misfirepolicy.calendarjob=/ s/=.*/=$JS_SCHEDULER_CALENDARJOB_MISFIRE_POLICY/" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/$QUARTZ_PROPS_FILE
  fi
}

set_quartz_governor_jasperreports_properties () {
  QUARTZ_GOVERNOR_PROPS_FILE="jasperreports.properties"
  if [ ! -z "$JS_SCHEDULER_REPORT_GOVERNOR_MAXPAGES" ]; then
    echo "updating governor.max.pages...."
    sed -i -e "/net.sf.jasperreports.governor.max.pages=/ s/=.*/=$JS_SCHEDULER_REPORT_GOVERNOR_MAXPAGES/" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/classes/$QUARTZ_GOVERNOR_PROPS_FILE
  fi
}

set_chrome_properties() {
    echo "updating chrome path...."
      if grep -q "chrome.path=" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/$JS_CONFIG_PROPERTIES_FILE;
      then
      sed -i -e "/chrome.path=/ s/=.*/=\/opt\/google\/chrome\/google-chrome/" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/$JS_CONFIG_PROPERTIES_FILE
      else
      echo 'chrome.path='/opt/google/chrome/google-chrome >> $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/$JS_CONFIG_PROPERTIES_FILE
      fi

    if [ ! -z "$JS_CHROME_TIMEOUT" ]; then
      echo "updating chrome.timeout...."
      if grep -q "chrome.page.timeout=" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/$JS_CONFIG_PROPERTIES_FILE;
      then
      sed -i -e "/chrome.page.timeout=/ s/=.*/=$JS_CHROME_TIMEOUT/" $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/$JS_CONFIG_PROPERTIES_FILE
      else
      echo 'chrome.page.timeout='$JS_CHROME_TIMEOUT >> $CATALINA_HOME/webapps/$JSFT_DEF_WEBAPP_NAME/WEB-INF/$JS_CONFIG_PROPERTIES_FILE
      fi
  fi

}

set_jvm_args() {
    [[ $JS_JVM_ARGS && ${JS_JVM_ARGS-x} ]] && (echo "JS_JVM_ARGS Found";rewrite_setenv_file) \
       || (echo -e "\033[33mJS_JVM_ARGS 'Not' Found. No change in JVM options. Proceed with OOTB settings.\033[0m")
}

rewrite_setenv_file() {
    echo
    echo -e "\033[33m$dateAndTime : Configuring new JVM options [ $JS_JVM_ARGS ] for Tomcat Services of Jaspersoft Server \033[0m"
    echo
    rm -rf $CATALINA_HOME/bin/setenv.sh
    echo 'export JAVA_OPTS="$JAVA_OPTS' $JS_JVM_ARGS'"' > $CATALINA_HOME/bin/setenv.sh
    echo 'export UMASK="0022"' >> $CATALINA_HOME/bin/setenv.sh
}

add_container_metadata_as_java_args() {
    if [ ! -z "$CONTAINER_METADATA_INFO" ]; then
        echo
        print "Adding container metadata as Java process argument"
        echo
        echo 'export JAVA_OPTS="$JAVA_OPTS -Dcontainer.metadata.info=${CONTAINER_METADATA_INFO}"' >> $CATALINA_HOME/bin/setenv.sh
    fi
}

modify_log_filename () {

    if [ ! -z "$CONTAINER_METADATA_INFO" ]; then
        echo
        print "Initiating operations for Jaspersoft configuration setup"
        echo


        sed -i -e "s| = catalina.*$| = \$\{container.metadata.info\}catalina\.|g;" $TOMCAT_LOGGING_PROP
        sed -i -e "s| = localhost.*$| = \$\{container.metadata.info\}localhost\.|g;" $TOMCAT_LOGGING_PROP
        sed -i -e "s| = manager.*$| = \$\{container.metadata.info\}manager\.|g;" $TOMCAT_LOGGING_PROP
        sed -i -e "s| = host-manager.*$| = \$\{container.metadata.info\}host-manager\.|g;" $TOMCAT_LOGGING_PROP

        sed -i -e "s| prefix=\"localhost_access_log\"| prefix=\"\$\{container.metadata.info\}localhost_access_log\"|g;" $TOMCAT_SERVER_XML

        sed -i -e "s|/logs/jasperserver.log.*$|/logs/\$\{sys\:container.metadata.info\}jasperserver.log|g;" $JSFT_LOGGING_PROP
        sed -i -e "s|/logs/jasperserver.%i.log.gz.*$|/logs/\$\{sys\:container.metadata.info\}jasperserver.%i.log.gz|g;" $JSFT_LOGGING_PROP


        sed -i -e "s|/logs/jasperanalysis.log.*$|/logs/\$\{sys\:container.metadata.info\}jasperanalysis.log|g;" $JSFT_LOGGING_PROP
        sed -i -e "s|/logs/jasperanalysis.%i.log.gz.*$|/logs/\$\{sys\:container.metadata.info\}jasperanalysis.%i.log.gz|g;" $JSFT_LOGGING_PROP

        #adding container metadata to WEB-INF/applicationContext-virtual-data-source.xml in transaction logs 
        sed -i -e "s|transactionBtm1.tlog|\#\{systemProperties\[\'container.metadata.info\'\]\}transactionBtm1.tlog|g;" $SPRING_APPC_VDS_XML
        sed -i -e "s|transactionBtm2.tlog|\#\{systemProperties\[\'container.metadata.info\'\]\}transactionBtm2.tlog|g;" $SPRING_APPC_VDS_XML
    fi
}

set_orchestration_metadata() {

    echo
    echo "Setting up Orchestration Metadata for the container..."
    echo
    source $METADATA_SCRIPT
    set_log_file_path
    echo
    print "CONTAINER METADATA INFO value - $CONTAINER_METADATA_INFO"
    echo
}

run_jasperserver() {
  # Start tomcat.
  start=`date +%s`

  print "Starting Tomcat Services for Jaspersoft Server"
  cd $CATALINA_HOME/bin
  exec ./catalina.sh run

  end=`date +%s`
   _cal_runtime_ $start $end "run_jasperserver"
}

validate_active_mq_cluster_connection (){
    start=`date +%s`
    _validate_activemq=55
    TCP_SOCKET_CONN=""

    print "Validating TCP Socket Connection for ActiveMQ Broker Service for ActiveMQ Cluster!!"
    if [ "$JS_EHCACHE_CONFIG" = "jms" -a "$JS_DEPLOYMENT_ENV_TYPE" = "multi-node" ]; then

        a=0;
        while [[ $a -lt $ACTIVEMQ_REPLICA_COUNT ]];
        do
            TCP_SOCKET_CONN=`echo "activemq-${a}.activemq-broker-headless-service:61616" | sed -e "s/\:/\//g"`
            print "TCP Socket Connection for ActiveMQ Broker Service : $TCP_SOCKET_CONN" "GREEN"
            </dev/tcp/$TCP_SOCKET_CONN
            _VALID_SERVER_PORT=$?

            print "TCP Socket Connection Validation Exit Code : $_VALID_SERVER_PORT"

            if [ $_VALID_SERVER_PORT -eq 0 ]; then
                print "Found valid ActiveMQ server and port : $TCP_SOCKET_CONN"  "GREEN"
                _validate_activemq=0
                break
            fi
            a=`expr $a + 1`;
        done
    else
        print "ActiveMQ Server & Port validation is NOT required." "GREEN"
    fi

    end=`date +%s`
    _cal_runtime_ $start $end "validate_active_mq_cluster_connection"

    print "Validation of ActiveMQ Master slave connection :: $_validate_activemq"
    if [ $_validate_activemq -gt 0 ]; then
        print "Invalid ActiveMQ server and port : $TCP_SOCKET_CONN" "RED"
        print "UNABLE to connect to ActiveMQ message connector port...$TCP_SOCKET_CONN" "RED"
        print "Correct the ActiveMQ connections and retry again" "RED"
        print "OR try to deploy single-node Jaspersoft by setting environment variable - 'JS_DEPLOYMENT_ENV_TYPE=single-node'" "RED"
        print "OR try using single activemq by setting environment variable - 'IS_ACTIVEMQ_MASTER_SLAVE=false'" "RED"
        exit $_validate_activemq
    fi
}

validate_active_mq_connection (){
    start=`date +%s`
    _validate_activemq=0

    print "Validating TCP Socket Connection for ActiveMQ Broker Service for ActiveMQ Standalone!!"
    if [ "$JS_EHCACHE_CONFIG" = "jms" -a "$JS_DEPLOYMENT_ENV_TYPE" = "multi-node" ]; then

        TCP_SOCKET_CONN=`echo "$ACTIVEMQ_PROVIDER_HOST_PORT" | sed -e "s/\:/\//g"`
        print "TCP Socket Connection for ActiveMQ Broker Service : $TCP_SOCKET_CONN" "GREEN"
        </dev/tcp/$TCP_SOCKET_CONN
        _VALID_SERVER_PORT=$?
        print "TCP Socket Connection Validation Exit Code : $_VALID_SERVER_PORT"

        if [ $_VALID_SERVER_PORT -eq 0 ]; then
            print "Found valid ActiveMQ server and port : $ACTIVEMQ_PROVIDER_HOST_PORT" "GREEN"
        else
            print "Invalid ActiveMQ server and port : $ACTIVEMQ_PROVIDER_HOST_PORT" "RED"
            print "UNABLE to connect to ActiveMQ message connector port...$ACTIVEMQ_PROVIDER_HOST_PORT" "RED"
            print "Correct the ActiveMQ connections and retry again" "RED"
            print "OR try to deploy single-node Jaspersoft by setting environment variable - 'JS_DEPLOYMENT_ENV_TYPE=single-node'" "RED"
            _validate_activemq=55
        fi
    else
        print "ActiveMQ Server & Port validation is NOT required." "GREEN"
    fi

    end=`date +%s`
    _cal_runtime_ $start $end "validate_active_mq_connection"

    print "Validation of ActiveMQ connection :: $_validate_activemq"
    if [ $_validate_activemq -gt 0 ]; then
        exit $_validate_activemq
    fi
}

fetchInputValue() {
  eval "input=\${$1}"
  echo "$input"
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

validate_properties () {
    validate_property "CONTAINER_LOG_FORMAT" "EMPTY_CHECK,VALUE_CHECK" "true,false"
    if [ "$CONTAINER_LOG_FORMAT" = "true" ]; then
        validate_property "POD_NAME" "EMPTY_CHECK"
        validate_property "POD_NAMESPACE" "EMPTY_CHECK"
    fi

    validate_property "JS_DPY_ENV" "EMPTY_CHECK,VALUE_CHECK" "op,od"
    validate_property "JS_DPY_ENV_COMPLIANCE" "EMPTY_CHECK,VALUE_CHECK" "standard,fedramp"
    validate_property "JS_LOG_HOST" "EMPTY_CHECK"
    validate_property "JS_ISOLATE_SCHEDULER" "EMPTY_CHECK,VALUE_CHECK" "true,false"
    validate_property "JS_SCH_INS" "EMPTY_CHECK,VALUE_CHECK" "true,false"

    validate_property "JS_INSTALL_METHOD" "EMPTY_CHECK,VALUE_CHECK" "new,upgrade"
    validate_property "JS_INSTALL_MODE" "EMPTY_CHECK,VALUE_CHECK" "standalone,cluster"
    validate_property "JS_INSTALL_MODE_TYPE" "EMPTY_CHECK,VALUE_CHECK" "minimal,deploy-webapp"
    validate_property "JS_MULTI_NODE" "EMPTY_CHECK,VALUE_CHECK" "true,false"
    validate_property "JS_DB_TYPE" "EMPTY_CHECK,VALUE_CHECK" "oracle,sqlserver"

    if [ "$JS_DB_TYPE" = "oracle" ]; then
        validate_property "JS_DB_ORCL_TYPE" "EMPTY_CHECK,VALUE_CHECK" "standalone,cluster"
        validate_property "JS_ORCL_SID_SRVNAME" "EMPTY_CHECK"
        validate_property "JS_DB_PORT" "EMPTY_CHECK,NUMBER_CHECK"
    fi

    if [ "$JS_DB_TYPE" = "sqlserver" ]; then
        validate_property "JS_IS_NAMED_INSTANCE" "EMPTY_CHECK,VALUE_CHECK" "true,false"
        if [ "$JS_IS_NAMED_INSTANCE" = "true" ]; then
            validate_property "JS_DB_SQLSERVER_INSTANCE_NAME" "EMPTY_CHECK"
        else
            validate_property "JS_DB_PORT" "EMPTY_CHECK,NUMBER_CHECK"
        fi
    fi

    validate_property "JS_DB_HOST" "EMPTY_CHECK"
    validate_property "JS_DB_UNAME" "EMPTY_CHECK"
    validate_property "JS_DB_PWD" "EMPTY_CHECK"
    validate_property "JS_SYSDB_UNAME" "EMPTY_CHECK"
    validate_property "JS_SYSDB_PWD" "EMPTY_CHECK"
    validate_property "JS_DB_NAME" "EMPTY_CHECK"

    validate_property "JS_MAIL_SETUP" "EMPTY_CHECK,VALUE_CHECK" "true,false"
    if [ "JS_MAIL_SETUP" = "true" ]; then
        validate_property "JS_MAIL_HOST" "EMPTY_CHECK"
        validate_property "JS_MAIL_PROTOCOL" "EMPTY_CHECK"
        validate_property "JS_MAIL_SENDER_UNAME" "EMPTY_CHECK"
        validate_property "JS_MAIL_SENDER_PWD" "EMPTY_CHECK"
        validate_property "JS_MAIL_SENDER_FROM" "EMPTY_CHECK"
        validate_property "JS_MAIL_PORT" "EMPTY_CHECK,NUMBER_CHECK"
    fi
}

validate_property () {
  _propertyName=$1
  eval "_property=\${$1}"
  _operations=$2
  _values=$3
  print "validating $_propertyName"
  print "value: $_property"

  IFS=',' read -ra ADDR <<< "$_operations"
  for _validation in "${ADDR[@]}"; do
     echo "validation - $_validation"
      if [ "$_validation" = "EMPTY_CHECK" ]; then
        if ! [[ $_property && ${_property-x} ]]; then
            print "$_propertyName 'Not' Found" "RED"
            exit 1
        fi
      fi

      if [ "$_validation" = "NUMBER_CHECK" ]; then
        re='^[0-9]+$'
        if ! [[ $_property =~ $re ]] ; then
           print "$_propertyName is not a valid number" "RED"
           exit 1
        fi
      fi

      if [ "$_validation" = "VALUE_CHECK" ]; then
        valid="false"
        IFS=',' read -ra VALS <<< "$_values"
        for val in "${VALS[@]}"; do
            if [ $val = $_property ]; then
                valid="true"
            fi
        done
        if [ $valid = "false" ]; then
            print "$_propertyName has invalid value" "RED"
            exit 1
        fi
      fi
  done
}

echo
echo "Initiating operations for JSFT configuration setup"
echo "ARGS_OPS:::: $ARGS_OPS"
echo
main_
_final_status=$?
if [ "$SLEEP_MODE" -a "$SLEEP_MODE" = "true" ]; then
    print "Going into sleep mode"
    trap : TERM INT; sleep infinity & wait
else
    print "Exiting with status $_final_status"
    exit $_final_status
fi
