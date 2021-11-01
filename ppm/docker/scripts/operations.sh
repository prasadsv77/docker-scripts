#!/bin/bash
CURRENT_FILE="$(basename "${BASH_SOURCE[0]}")"
source $PPM_HOME_SCRIPTS/cd-checkinstall.sh
set_orchestration_metadata() {
source $PPM_HOME_SCRIPTS/populate-container-metadata.sh
print "CONTAINER METADATA INFO value - $CONTAINER_METADATA_INFO" "GREEN"
}

set_orchestration_metadata
dateAndTime=$(date +"%Y-%m-%d_%H.%M.%S")

#Populate user input timezone
populateTimeZone

# Creating default symlinks for properties.xml and logger.xml
loadDefaultConfigurationFiles
setDefaultSymlinks
# load release override files based on release version
load_release_overrides

createDiagnosticFolder

if [ ! -f "$PPM_HOME/config/properties.xml" ]
then
  print "Configuration file properties.xml does not exist..." "RED"
  exit 1
fi

ARG_COUNT=$#
ARGS=${1}

: ${PPM_INSTALL_DB_FILE:=install-db.sh}
: ${PPM_INSTALL_ADDINS_FILE:=install-addins.sh}
: ${PPM_MAINTENANCE_FILE:=maintenance.sh}
: ${PPM_INTEGRATION_FILE:=integrations.sh}
: ${PPM_INSTALL_PLUGINS_FILE:=install-plugins.sh}
: ${PPM_DR_FILE:=dr.sh}

load_configs ( ) {
    print "Loading configuration files..."
    #Read properties from optional configuration files
    for f in $PPM_HOME/input/configs/*
    do
      if [ -f "$f" ]; then
        print "Sourcing configuration file $f" "GREEN"
        source $f
      fi
    done
}

ppm_installation () {
    print "Initiating operations for PPM configuration setup - $@" "YELLOW"
    if [ $ARG_COUNT -eq 0 ]
    then
        print "No arguments provided. Please provide valid operation 'INSTALL_DB|INSTALL_ADDINS|INIT_MAINTENANCE|INIT_UPGRADE|INIT_INTEGRATIONS'" "RED"
        exit 1
    else
        print "Generating mandatory keys for dependency management"
        DEPENDENCY_MGMT_KEYS=`getMandatoryKeys`
        print "DEPENDENCY_MGMT_KEYS:$DEPENDENCY_MGMT_KEYS"
        IFS='|' read -a operations <<< "$ARGS"
        # Enabling password encryption through update use case is just setting the flag encrypt passwords to true but not actually encrypting passwords in properties.xml.
        # TODO Added this command so that passwords will be encrypted. This should be removed once the product issue is figured out.
        $PPM_HOME/bin/admin general validate > /dev/null
        _pod_status=0
        for i in "${operations[@]}"
        do
            if [ "$i" == "INSTALL_DB" ]
            then
                print "Initiating installation of PPM DB Schemas"
                if [ -f "$PPM_HOME_SCRIPTS/$PPM_INSTALL_DB_FILE" ]; then
                    source "$PPM_HOME_SCRIPTS/$PPM_INSTALL_DB_FILE"
                    _status=$?
                    if test $_status -ne 0; then
                        print "Operation failed."
                        _pod_status=1
                        break
                    fi
                else
                    print "ERROR! db installation script does not exist" "RED"
                fi

            elif [ "$i" == "INSTALL_ADDINS" ]
            then
                print "Initiating installation of PPM Addins"
                if [ -f "$PPM_HOME_SCRIPTS/$PPM_INSTALL_ADDINS_FILE" ]; then
                    source "$PPM_HOME_SCRIPTS/$PPM_INSTALL_ADDINS_FILE"
                    _status=$?
                    if test $_status -ne 0; then
                        print "Operation failed."
                        _pod_status=1
                        break
                    fi
                else
                    print "ERROR! addins installation script does not exist" "RED"
                fi

            elif [ "$i" == "INSTALL_PLUGINS" ]
            then
                print "Initiating installation of PPM Plugins"
                if [ -f "$PPM_HOME_SCRIPTS/$PPM_INSTALL_PLUGINS_FILE" ]; then
                    source "$PPM_HOME_SCRIPTS/$PPM_INSTALL_PLUGINS_FILE"
                    _status=$?
                    if test $_status -ne 0; then
                        print "Operation failed."
                        break
                    fi
                else
                    print "ERROR! plugins installation script does not exist" "RED"
                fi

            elif [ "$i" == "INIT_MAINTENANCE" ]
            then
                print "Initiating PPM maintenance mode"
                if [ -f "$PPM_HOME_SCRIPTS/$PPM_MAINTENANCE_FILE" ]; then
                    source "$PPM_HOME_SCRIPTS/$PPM_MAINTENANCE_FILE"
                else
                    print "ERROR! maintainance script does not exist" "RED"
                fi

            elif [ "$i" == "INIT_UPGRADE" ]
            then
               print "Initiating upgrade for PPM services"
                if [ -f "$PPM_HOME_SCRIPTS/$PPM_INSTALL_DB_FILE" ]; then
                    source "$PPM_HOME_SCRIPTS/$PPM_INSTALL_DB_FILE" "upgrade"
                else
                    print "ERROR! upgrade db installation script does not exist" "RED"
                fi

            elif [ "$i" == "INIT_INTEGRATIONS" ]
            then
                if [ -f "$PPM_HOME_SCRIPTS/$PPM_INTEGRATION_FILE" ]; then
                    source "$PPM_HOME_SCRIPTS/$PPM_INTEGRATION_FILE"
                    _status=$?
                    if test $_status -ne 0; then
                        print "Operation failed."
                        _pod_status=1
                    fi
                else
                    print "ERROR! integration script does not exist" "RED"
                fi

            #@TODO: Temporary while deploying DB image we will call SLEEP INFINITY to avoid respawn the DB instances since current CI/CD pipeline support only DeploymentConfig. In this model the pod never killed and once completed the operation, as default behaviour tries to respawn.
            elif [ "$i" == "SLEEP_INFINITY" ]
            then
                print "Script will wait here for a stop request"
                trap : TERM INT; sleep infinity & wait

            else
               print "Invalid operation - '$i'. No operations performed." "RED"
               exit 1
            fi
        done

        if [[ "$ENABLE_CHECKINSTALL" = "true" ]]; then
          if [[ "$PPM_INSTALL_TYPE" = "upgrade" || "$PPM_INSTALL_TYPE" = "patch"  ]]; then
            perform_post_check
            _post_check_status=$?
            if test $_post_check_status -eq 0; then
               print "Post check validation is successful."
            else
              print "Post check validation has failed."
              exit 1
            fi
          fi
          if [[ "$PPM_INSTALL_TYPE" = "new" ]]; then
             print "Check install is not supported for install type as new"
          fi
        fi

        if [  ! -z $DEPENDENCY_MGMT_KEYS ]
        then
            CURRENT_FILE="$(basename "${BASH_SOURCE[0]}")"
            check_status_in_config_map $CURRENT_FILE "final"
            _final_status=$?
        else
            print "No mandatory operations are requested. Hence updating the final status as success."
            _final_status=0
        fi

        if test $_final_status -eq 0; then
           insert_release_overrides_history
           print "All mandatory operations are completed.Updating the status in config map"
           updateOperationStatusToken
        else
           print "All required operations are not completed. Please check the logs." "RED"
           exit 1
        fi
    fi
}

main_ () {
  load_configs

  if [ "$PPM_INSTALL_TYPE" = "DR" ]; then
    source "$PPM_HOME_SCRIPTS/$PPM_DR_FILE"
  else
    if [ "$PPM_INSTALL_TYPE" = "new" ] || [ "$PPM_INSTALL_TYPE" = "patch" ] || [ "$PPM_INSTALL_TYPE" = "upgrade" ]; then
      if [[ "$ENABLE_CHECKINSTALL" = "true" ]]; then
        if [[ "$PPM_INSTALL_TYPE" = "upgrade" || "$PPM_INSTALL_TYPE" = "patch"  ]]; then
          perform_pre_check
          _pre_check_status=$?
          if test $_pre_check_status -eq 0; then
             print "Pre check validation is successful."
          else
            print "Pre check validation has failed."
            exit 1
          fi
        fi
        if [[ "$PPM_INSTALL_TYPE" = "new" ]]; then
           print "Check install is not supported for install type as new"
        fi
      fi
      ppm_installation
    else
      print "WARNING! None of the DB operations were triggered. Please check db related environment variables." "RED"
      #exit 1
    fi
  fi

}

main_
