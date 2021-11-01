#!/bin/bash

set_orchestration_metadata() {
source $PPM_HOME_SCRIPTS/populate-container-metadata.sh
print "CONTAINER METADATA INFO value - $CONTAINER_METADATA_INFO" "GREEN"
}

set_orchestration_metadata
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

add_deploy_ppm_service ( ) {
    print "Services to be deployed .... beacon $PPM_START_SERVICES"
    #@todo what if one service fails and others passes - do individual add deploy of services
    if [ "$PPM_START_SERVICES" != "" ]; then
      $PPM_HOME/bin/service add deploy beacon $PPM_START_SERVICES
    fi
    ADD_SERVICE_RESULT=$?

    if [ $ADD_SERVICE_RESULT -eq 0 ]; then
      print "ADD and DEPLOY SERVICES SUCCESSFUL..."
    else
      print "ADD and DEPLOY SERVICES FAILED..." "RED"
      exit 1
    fi
}

ppm_start_services ( ) {
    print "Services to be started .... $PPM_START_SERVICES"
    #@todo what if one service fails and others passes - do individual start of services
    if [ "$PPM_START_SERVICES" != "" ]; then
      $PPM_HOME/bin/service start $PPM_START_SERVICES
    fi
    START_SERVICE_RESULT=$?

    if [ $START_SERVICE_RESULT -eq 0 ]; then
      print "STARTED SERVICES SUCCESSFULLY..."
    else
      print "START SERVICES FAILED..." "RED"
      return 1
    fi
}

ppm_start_cmd_services ( ) {
    print "Starting command ... $PPM_START_COMMAND"
    $PPM_HOME/bin/$PPM_START_COMMAND
}

signal_term_handler(){
   print "Stop request received for graceful shutdown..."

   # Identify the PPM service PID
   SERVICE_PID=`ps h -C java -o "%p:%a" | grep $PPM_START_SERVICES | cut -d: -f1`
   # Stop the PPM service
   $PPM_HOME/bin/service stop $PPM_START_SERVICES

   # Wait container to exit until PPM service PID is no more exist
   while [[ ${?} == 0 ]]
   do
     print "Waiting to stop $PPM_START_SERVICES service..."
     sleep 1s
     ps -p $SERVICE_PID > /dev/null
   done

   print "Successfully completed graceful shutdown"
   exit 0
}

trap 'signal_term_handler' SIGTERM

if [ $# -eq 0 ]; then
    print "No Service passed as argument. Set all services for start"
    export PPM_START_SERVICES="app bg"
else
    # services passed as arguments
    export PPM_START_SERVICES="${@}"
fi

if [[ $PPM_START_SERVICES = "app" && $HOME_PAGE = "mux" ]]
then
    print "Redirecting landing page to PPM UX..."
    sed -i "s|<script>location\.replace(.*);</script>|<script>location.replace(\"pm\");</script>|" "$PPM_HOME/.setup/templates/docroot/index.html"
fi
sed -i "s|securityLogs.xml|securityContainerLogs.xml|" "$PPM_HOME/META-INF/security/config/securityDescriptor.xml"
add_deploy_ppm_service
if [ "$PPM_START_COMMAND" != "" ]; then
    ppm_start_cmd_services
else
    ppm_start_services
    VALIDATE_PPM_START_RETURN_CODE=$?
    if [ "$VALIDATE_PPM_START_RETURN_CODE" -eq "0" ]; then
      # wait forever, otherwise the container will stop
      while true
      do
        tail -f /dev/null & wait ${!}
      done
    else
       exit 1
    fi
fi
