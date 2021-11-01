#!/bin/bash
IMPORT_STATUS_PROP_KEY="CLRT_DB_IMPORT_STATUS"
IMPORT_ADD_IN_STATUS_PROP_KEY="CLRT_ADD-IN_IMPORT_STATUS"
IMPORT_REDO_PROP_KEY="CLRT_REDO_IMPORT"
IMPORT_CONCURRENCY_PROP_KEY="CLRT_IMPORT_TS"
STATUS_FLAG_DONE=999
CONFIGMAP_NAME="config-map-clarity-db-status"
ORCHESTRATION_CLIENT_FOLDER="/opt/orchestration/client"
RELEASE="15.6.1"
CURRENT_FILE="$(basename "${BASH_SOURCE[0]}")"

print_command() {
    # mask the privileged properties for e.g. password
    # e.g. _command="$PPM_HOME/bin/admin db import-backup -Dbackup.directory=/opt/db -Dsysusername=pradeep -Dsyspassword=pradeep -DtenantId=clarity -Dbackup.name=file.db -Dtodatabase=dbservice -Dusername=abcd"
    _command=$1
    _mask_command=''

    OIFS=$IFS
    IFS=' '
    for x in $_command
    do
        if [[ "$x" == *"password"* ]]; then
           _mask_command+=$(echo "$x" | sed "s/\=.*/=*****/g")
         else
           _mask_command+=$x
         fi
         _mask_command+=' '
    done
    IFS=$OIFS

    print "$_mask_command"
}

ppm_tenant_db_setup ( ) {
    #check config map before starting db import
    check_status_in_config_map $CURRENT_FILE "db"
    _config_status=$?
    if test $_config_status -ne 0; then
        ################  On-Board tenant Databases ######################
        print "Importing PPM schema for single tenant mode..."
        print "PPM_DB_VENDOR:$PPM_DB_VENDOR"
        _db_import_command_args=""
        if [ "$PPM_DB_VENDOR" = "mssql" ]; then
          _db_import_command_args="-Dbackup.directory=$PPM_DB_BACKUP_DIR -Dsysusername=$PPM_DB_PRIVILEGED_USER -Dsyspassword=$PPM_DB_PRIVILEGED_USER_PWD -DtenantId=$PPM_TENANT_ID -Dbackup.name=$PPM_DB_BACKUP_FILE -Dtodatabase=$PPM_DB_SERVICE_ID"
        elif [ "$PPM_DB_VENDOR" = "oracle" ]; then
          populateDBCustomTableSpaces
          _db_import_command_args="-Dbackup.directory=$PPM_DB_BACKUP_DIR -Dsysusername=$PPM_DB_PRIVILEGED_USER -Dsyspassword=$PPM_DB_PRIVILEGED_USER_PWD -DtenantId=$PPM_TENANT_ID -Dbackup.name=$PPM_DB_BACKUP_FILE -DuseTableSpaceRemapping=true -DfromlargeIndex=$PPM_DB_SRC_INDX_LARGE_TS -DfromsmallIndex=$PPM_DB_SRC_INDX_SMALL_TS -DfromlargeTables=$PPM_DB_SRC_USERS_LARGE_TS -DfromsmallTables=$PPM_DB_SRC_USERS_SMALL_TS -DtolargeIndex=$PPM_DB_INDX_LARGE_TS -DtosmallIndex=$PPM_DB_INDX_SMALL_TS -DtolargeTables=$PPM_DB_USERS_LARGE_TS -DtosmallTables=$PPM_DB_USERS_SMALL_TS"
        elif [ "$PPM_DB_VENDOR" = "postgres" ]; then
          populateDBCustomTableSpaces
          _db_import_command_args="-Dsysusername=$PPM_DB_PRIVILEGED_USER -Dsyspassword=$PPM_DB_PRIVILEGED_USER_PWD -DtenantId=$PPM_TENANT_ID -DuseTableSpaceRemapping=true -DfromlargeIndex=$PPM_DB_SRC_INDX_LARGE_TS -DfromsmallIndex=$PPM_DB_SRC_INDX_SMALL_TS -DfromlargeTables=$PPM_DB_SRC_USERS_LARGE_TS -DfromsmallTables=$PPM_DB_SRC_USERS_SMALL_TS -DtolargeIndex=$PPM_DB_INDX_LARGE_TS -DtosmallIndex=$PPM_DB_INDX_SMALL_TS -DtolargeTables=$PPM_DB_USERS_LARGE_TS -DtosmallTables=$PPM_DB_USERS_SMALL_TS"
          if [ ! -z "$PPM_DB_BACKUP_DIR" ]; then
            _db_import_command_args+=" -Dbackup.directory=$PPM_DB_BACKUP_DIR"
          fi
          if [ ! -z "$PPM_DB_BACKUP_FILE" ]; then
            _db_import_command_args+=" -Dbackup.name=$PPM_DB_BACKUP_FILE"
          fi
        else
          print 'ERROR: PPM_DB_VENDOR must be oracle or mssql or postgres in lower case' "RED"
          return 1
        fi

        if [ ! -z "$PPM_DB_FROM_DATABASE" ]; then
          _db_import_command_args+=" -Dfromdatabase=$PPM_DB_FROM_DATABASE"
        fi
        if [ ! -z "$PPM_DB_FROM_USERNAME" ]; then
          _db_import_command_args+=" -Dfromusername=$PPM_DB_FROM_USERNAME"
        fi
        if [ ! -z "$PPM_DB_FROM_SCHEMANAME" ]; then
          _db_import_command_args+=" -Dfromschemaname=$PPM_DB_FROM_SCHEMANAME"
        fi

        print_command "$PPM_HOME/bin/admin db import-backup $_db_import_command_args"
        $PPM_HOME/bin/admin db import-backup $_db_import_command_args

        CMD_PPM_RESULT=$?
        move_db_import_logs "${PPM_HOME}"/database/backups/*import.log "${PPM_HOME}"/logs/container/"$CONTAINER_METADATA_INFO"-pg-import.log

        if [ $CMD_PPM_RESULT -eq 0 ]; then
          validate_and_update_config_map "db" "db_health"
          _validation_status=$?
          if test $_validation_status -eq 0; then
            print "Importing PPM schema is successful..."
            return 0
          else
            print "Importing PPM schema failed." "RED"
            return 1
          fi
        else
          print "Importing PPM schema failed..." "RED"
          return 1
        fi
    else
        if [[ "$PPM_INSTALL_TYPE" == "new" ]]; then
          # Validate db against with the runtime version, if matches then continue the with the remaining operations
          validate_db_status_and_exit db_health
        fi

        print "DB Import is already done."
        return 0
    fi
}

ppm_dwh_tenant_db_setup ( ) {
    #check config map before starting dwh import
    check_status_in_config_map $CURRENT_FILE "dwh"
    _config_status=$?
    if test $_config_status -ne 0; then
        print "Importing DWH schema for single tenant mode..."
        _dwh_import_command_args=""

        if [ "$PPM_DWH_DB_VENDOR" = "mssql" ]; then
          _dwh_import_command_args="-Ddwh.backup.directory=$PPM_DWH_BACKUP_DIRECTORY -Ddwhsysusername=$PPM_DB_PRIVILEGED_USER -Ddwhsyspassword=$PPM_DB_PRIVILEGED_USER_PWD -Ddwh.backup.name=$PPM_DWH_BACKUP_FILE -Dtodatabase=$PPM_DWH_DB_SERVICE_ID -DtenantId=$PPM_TENANT_ID"
        elif [ "$PPM_DWH_DB_VENDOR" = "oracle" ]; then
          populateDWHCustomTableSpaces
          _dwh_import_command_args="-Ddwh.backup.directory=$PPM_DWH_BACKUP_DIRECTORY -Ddwhsysusername=$PPM_DB_PRIVILEGED_USER -Ddwhsyspassword=$PPM_DB_PRIVILEGED_USER_PWD -Ddwh.backup.name=$PPM_DWH_BACKUP_FILE -DtenantId=$PPM_TENANT_ID -DuseTableSpaceRemapping=true -DfromdimTables=$PPM_DWH_SRC_DATA_DIM_TS -DfromfactTables=$PPM_DWH_SRC_DATA_FACT_TS -DfromdimIndex=$PPM_DWH_SRC_INDX_DIM_TS -DfromfactIndex=$PPM_DWH_SRC_INDX_FACT_TS -DtodimTables=$PPM_DWH_DATA_DIM_TS -DtofactTables=$PPM_DWH_DATA_FACT_TS -DtodimIndex=$PPM_DWH_INDX_DIM_TS -DtofactIndex=$PPM_DWH_INDX_FACT_TS"
        elif [ "$PPM_DWH_DB_VENDOR" = "postgres" ]; then
          populateDWHCustomTableSpaces
          _dwh_import_command_args="-Ddwhsysusername=$PPM_DB_PRIVILEGED_USER -Ddwhsyspassword=$PPM_DB_PRIVILEGED_USER_PWD -DtenantId=$PPM_TENANT_ID -DuseTableSpaceRemapping=true -DfromdimTables=$PPM_DWH_SRC_DATA_DIM_TS -DfromfactTables=$PPM_DWH_SRC_DATA_FACT_TS -DfromdimIndex=$PPM_DWH_SRC_INDX_DIM_TS -DfromfactIndex=$PPM_DWH_SRC_INDX_FACT_TS -DtodimTables=$PPM_DWH_DATA_DIM_TS -DtofactTables=$PPM_DWH_DATA_FACT_TS -DtodimIndex=$PPM_DWH_INDX_DIM_TS -DtofactIndex=$PPM_DWH_INDX_FACT_TS"
          if [ ! -z "$PPM_DWH_BACKUP_DIRECTORY" ]; then
            _dwh_import_command_args+=" -Ddwh.backup.directory=$PPM_DWH_BACKUP_DIRECTORY"
          fi
          if [ ! -z "$PPM_DWH_BACKUP_FILE" ]; then
            _dwh_import_command_args+=" -Ddwh.backup.name=$PPM_DWH_BACKUP_FILE"
          fi
        else
          print 'ERROR: PPM_DWH_DB_VENDOR must be oracle or mssql or postgres in lower case' "RED"
          return 1
        fi

        if [ ! -z "$PPM_DWH_FROM_DATABASE" ]; then
          _dwh_import_command_args+=" -Ddwhfromdatabase=$PPM_DWH_FROM_DATABASE"
        fi
        if [ ! -z "$PPM_DWH_FROM_USERNAME" ]; then
          _dwh_import_command_args+=" -Ddwhfromusername=$PPM_DWH_FROM_USERNAME"
        fi
        if [ ! -z "$PPM_DWH_FROM_SCHEMANAME" ]; then
          _dwh_import_command_args+=" -Ddwhfromschemaname=$PPM_DWH_FROM_SCHEMANAME"
        fi

        print_command "$PPM_HOME/bin/admin db import-dwh-backup $_dwh_import_command_args"
        $PPM_HOME/bin/admin db import-dwh-backup $_dwh_import_command_args

        CMD_DWH_RESULT=$?
        move_db_import_logs "${PPM_HOME}"/database/backups/*import_dwh.log "${PPM_HOME}"/logs/container/"$CONTAINER_METADATA_INFO"-pg-import-dwh.log

        if [ $CMD_DWH_RESULT -eq 0 ]; then
          validate_and_update_config_map "dwh" "dwh_health"
          _validation_status=$?
          if test $_validation_status -eq 0; then
            print "Importing DWH schema is successful..."
            return 0
          else
            print "Importing DWH schema failed..." "RED"
            return 1
          fi
        else
          print "Importing DWH schema failed..." "RED"
          return 1
        fi
    else
        if [[ "$PPM_INSTALL_TYPE" == "new" ]]; then
          # Validate db against with the runtime version, if matches then continue the with the remaining operations
          validate_db_status_and_exit dwh_health
        fi

        print "DWH Import is already done."
        return 0
    fi
}

ppm_db_link_setup ( ) {
    #check config map before starting db import
    check_status_in_config_map $CURRENT_FILE "db_link"
    _config_status=$?
    if test $_config_status -ne 0; then
        print "Creating DB Link ..."
        ################# Create DBLink  ################
        $PPM_HOME/bin/admin db create-db-link
        CMD_DB_LINK_CREATE_RESULT=$?

        if [ $CMD_DB_LINK_CREATE_RESULT -eq 0 ]; then
            validate_and_update_config_map "db_link" "db_link_health"
            _validation_status=$?
            if test $_validation_status -eq 0; then
                print "PPM DB link setup completed successfully..."
                return 0
            else
                print "PPM DB link setup failed..." "RED"
                return 1
            fi
        else
            print "PPM DB link setup failed..." "RED"
            return 1
        fi
    else
        print "DB link setup is already done."
        return 0
    fi
}

ppm_tenant_db_upgrade ( ) {
    print "Upgrading PPM DB schemas..."
    print "$PPM_HOME/bin/admin db upgrade -Dupgrade.phase=upgrade"

    $PPM_HOME/bin/admin db upgrade -Dupgrade.phase=upgrade
    CMD_PPM_RESULT=$?

    if [ $CMD_PPM_RESULT -eq 0 ]; then
      print "Database upgrade is successful..."
      return 0
    else
      print "Database upgrade failed..." "RED"
      return 1
    fi
}

#@Todo: ppm_complete_db_setup - Check every function success and failure scenario's
ppm_complete_db_setup () {
    ppm_tenant_db_setup
    _cmd_db_setup=$?
    if test $_cmd_db_setup -eq 0; then
        print "DB import is successfully done."
        ppm_dwh_tenant_db_setup
        _cmd_db_dwh_setup=$?
        if test $_cmd_db_dwh_setup -eq 0; then
            print "DWH import is successfully done."

            # Process patch operation if it is patch
            if [ "$PPM_INSTALL_TYPE" = "patch" ]; then
              ppm_apply_db_patch
              _cmd_ppm_apply_db_patch=$?
              if test $_cmd_ppm_apply_db_patch -eq 0; then
                  # Loading version.properties file for patch version
                  source ${PPM_HOME}/.setup/version.properties

                  # Validate db against with the latest patch version
                  validate_patch_db_status_and_exit patch-db-status $package
                  validate_patch_db_status_and_exit patch-dwh-status $package

                  print "Patch DB processing is completed."
              else
                print "Patch DB installation is failed."
                exit 1
              fi
            fi

            # Process upgrade operation if it is upgrade
            if [ "$PPM_INSTALL_TYPE" = "upgrade" ]; then
              ppm_apply_db_upgrade
              _cmd_ppm_apply_db_upgrade=$?
              if test $_cmd_ppm_apply_db_upgrade -eq 0; then
                # Validate db against with the latest version
                validate_db_status_and_exit db_health
                validate_db_status_and_exit dwh_health

                print "Upgrade DB processing is completed."
              else
                print "Upgrade DB installation is failed."
                exit 1
              fi
            fi

            # upload configuration file into database
            upload_config

            #DB link creation
            ppm_db_link_setup
            _cmd_db_link_setup=$?
            if test $_cmd_db_link_setup -eq 0; then
              print "DB link setup is successfully done."
              return 0
            else
             print "DB link setup failed" "RED"
             return 1
            fi
        else
            print "DWH import failed"
            return 1
        fi
    else
        print "DB import failed"
        return 1
    fi

    _cmd_exec=$(( $_cmd_db_setup + $_cmd_db_dwh_setup + $_cmd_db_link_setup ))

    return $_cmd_exec
}

validate_db_status_and_exit (){
  db=$1
  print "Validating status for $db..."
  setup_validation $db
  _db_status=$?
  if test $_db_status -ne 0; then
    print "$db and runtime version check is failed. Hence, exiting with the failed state."
    exit 1
  fi
}

validate_patch_db_status_and_exit (){
  db=$1
  patch.version=$2
  print "Validating status for $db..."
  setup_validation $db $patch.version
  _db_status=$?
  if test $_db_status -ne 0; then
    print "Patch installation is failed."
    exit 1
  fi
}

# Upload properties.xml into database
upload_config (){
  print $PPM_HOME/bin/admin general upload-config
  $PPM_HOME/bin/admin general upload-config
}

ppm_apply_db_patch (){
  print $PPM_HOME/bin/admin cd process_db -Dispatch=true
  $PPM_HOME/bin/admin cd process_db -Dispatch=true
  _command_status=$?
  if test $_command_status -ne 0; then
      print "patch installation is failed while processing DB." "RED"
      return 1
  fi
}

ppm_apply_db_upgrade (){
  print $PPM_HOME/bin/admin cd upgrade_db
  $PPM_HOME/bin/admin cd upgrade_db
  _command_status=$?
  if test $_command_status -ne 0; then
      print "Upgrade installation is failed while processing DB." "RED"
      return 1
  fi
}

validate_and_update_config_map (){
         _check_item=$1
         print "_check_item - $_check_item"
         _check_function=$2
         print "_check_item - $_check_function"
   	     setup_validation $_check_function
         _setup_validation=$?
         if test $_setup_validation -eq 0; then
                print "$dateAndTime : Validation Passed - $_setup_validation" "GREEN"
                update_status_in_config_map $CURRENT_FILE $_check_item
                 _update_status=$?
                 print "Updation of ConfigMap Status Code: $_update_status"
                if [ "$_update_status" = "0" ]; then
                    print "ConfigMaps update successfully with status - $_update_status" "GREEN"
                    print "SUCCESS: Updated config map."
                    return 0
                else
                    print "ConfigMaps update failed with status - 44" "GREEN"
                    return 44
                fi
         else
                print "Validation Failed - 106" "RED"
                return 106
         fi
}

set_database_default_values ( ) {

 if [ "$PPM_DB_VENDOR" = "oracle" ]; then
    # Source tablespaces by default
    : ${PPM_DB_SRC_USERS_LARGE_TS:=USERS_LARGE}
    : ${PPM_DB_SRC_USERS_SMALL_TS:=USERS_SMALL}
    : ${PPM_DB_SRC_INDX_LARGE_TS:=INDX_LARGE}
    : ${PPM_DB_SRC_INDX_SMALL_TS:=INDX_SMALL}
 elif [ "$PPM_DB_VENDOR" = "postgres" ]; then
    # Source tablespaces by default
    : ${PPM_DB_SRC_USERS_LARGE_TS:=clarity_data}
    : ${PPM_DB_SRC_USERS_SMALL_TS:=clarity_data}
    : ${PPM_DB_SRC_INDX_LARGE_TS:=clarity_indx}
    : ${PPM_DB_SRC_INDX_SMALL_TS:=clarity_indx}
 fi

 if [ "$PPM_DWH_DB_VENDOR" = "oracle" ]; then
    # Source tablespaces by default
    : ${PPM_DWH_SRC_DATA_DIM_TS:=DWH_PPM_DATA_DIM}
    : ${PPM_DWH_SRC_DATA_FACT_TS:=DWH_PPM_DATA_FACT}
    : ${PPM_DWH_SRC_INDX_DIM_TS:=DWH_PPM_INDX_DIM}
    : ${PPM_DWH_SRC_INDX_FACT_TS:=DWH_PPM_INDX_FACT}
 elif [ "$PPM_DWH_DB_VENDOR" = "postgres" ]; then
    # Source tablespaces by default
    : ${PPM_DWH_SRC_DATA_DIM_TS:=clarity_dwh_data}
    : ${PPM_DWH_SRC_DATA_FACT_TS:=clarity_dwh_data}
    : ${PPM_DWH_SRC_INDX_DIM_TS:=clarity_dwh_indx}
    : ${PPM_DWH_SRC_INDX_FACT_TS:=clarity_dwh_indx}
 fi

}

setup_validation (){
    _check_function=$1
    PATCH_VERSION=$2
    source $PPM_HOME_SCRIPTS/healthcheck/dbhealthcheck.sh
    if [ "$_check_function" = "db_health" ]; then
        check_db_health "db-status" $CLARITY_RELEASE
    elif [ "$_check_function" = "dwh_health" ]; then
        check_db_health "dwh-status" $CLARITY_RELEASE
    elif [ "$_check_function" = "db_link_health" ]; then
        check_db_health "db-link-status" $CLARITY_RELEASE
    elif [ "$_check_function" = "patch_db_health" ]; then
      check_patch_db_health "patch-db-status" $CLARITY_RELEASE $PATCH_VERSION
    elif [ "$_check_function" = "patch_dwh_health" ]; then
        check_patch_db_health "patch-dwh-status" $CLARITY_RELEASE $PATCH_VERSION
    fi
    _db_check=$?
    return $_db_check
}

move_db_import_logs (){
  print "Moving DB import logs from database backup directory to logs directory"
  _from_location=$1
  _to_location=$2
  if [ -e "$_from_location" ]; then
    mkdir -p "${PPM_HOME}"/logs/container
    mv "$_from_location" "$_to_location"
  fi

}

if [[ "$PPM_SKIP_DB_IMPORT" == "false" || "$PPM_INSTALL_TYPE" == "upgrade" || "$PPM_INSTALL_TYPE" == "patch" ]]; then
  # In case of patch/upgrade ignore the skip_db_import to process patch/upgrade operations
  print "DB operations initiated..."
  set_database_default_values
  ppm_complete_db_setup
  _clarity_complete_db_setup_cmd=$?

  # Load default configurations for containers after DB setup/upgrade/patch is done.
  loadDefaultConfigurations

  if test $_clarity_complete_db_setup_cmd -eq 0; then
      print "Complete DB setup is done" "GREEN"
      print "STATUS of complete Operation is : $_clarity_complete_db_setup_cmd" "GREEN"
      echo
      print "Exiting with status as : $_clarity_complete_db_setup_cmd"
      return 0
  else
      print "Complete DB setup is not done" "RED"
      return 1
  fi
else
  validate_and_update_config_map "db" "db_health"
  validate_and_update_config_map "dwh" "dwh_health"
  validate_and_update_config_map "db_link" "db_link_health"
  # Validate db against with the runtime version, if matches then continue the with the remaining operations
  print "PPM_SKIP_DB_IMPORT is defined as $PPM_SKIP_DB_IMPORT, so DB operations skipped and continue for other operations by validating the db/dwh status..."
  validate_db_status_and_exit db_health
  validate_db_status_and_exit dwh_health

  # Load default configurations for containers after DB setup/upgrade/patch is done.
  loadDefaultConfigurations
fi

