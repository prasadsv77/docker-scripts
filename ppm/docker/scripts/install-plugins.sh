#!/bin/bash
CURRENT_FILE="$(basename "${BASH_SOURCE[0]}")"

db_validation (){
    _plug_in_passed=$1
    print "DB validation for plug  in : $_plug_in_passed"
    source $PPM_HOME_SCRIPTS/healthcheck/dbhealthcheck.sh
    check_plugin_health $CLARITY_RELEASE $_plug_in_passed
    _db_check=$?
    return $_db_check
}

install_plugin (){
  print "Installing PPM Plugin $1"
  echo
  print "PPM_HOME/bin/admin plugin $1"
  if [[ -z $2 ]]
  then
    $PPM_HOME/bin/admin plugin $1
  else
    $PPM_HOME/bin/admin plugin $1 -Dforce=true
  fi
}

is_plugin_installed (){
   db_validation $1
   _db_validation=$?
   print "Plugin installation DB querying status code - $_db_validation"
   if test $_db_validation -eq 0; then
      print "DB Validation Passed - $_db_validation" "GREEN"
   else
      print "DB Validation Failed - 106" "RED"
      return 106
   fi
}

install_ppm_plugins () {
    _plugin_id=$1
    _plugin=$(get_plugin $1)

    print "checking in config map if $_plugin plug in is already installed"
    check_status_in_config_map $CURRENT_FILE $_plugin
    _plugin_config_status=$?

    if [[ "$PPM_INSTALL_TYPE" = "upgrade" || "$PPM_INSTALL_TYPE" = "patch"  ]]; then
      # check whether plugin is already up-to-date with latest version
      is_plugin_installed $_plugin_id > /dev/null # do not print/capture logs, in case of failure we need to proceed to install.
      _db_validation=$?
      if test $_db_validation -eq 0; then
        if test $_plugin_config_status -eq 0; then
          print "$_plugin is already upgraded to latest release." "GREEN"
          return 0
        else
         install_and_exit_plugin
        fi
      else
       install_and_exit_plugin
      fi
    else # In case of new
      if test $_plugin_config_status -eq 0; then # Compare restart token
        print "Plug in $_plugin is already installed."
        return 0
      else
        print "Either Plugin $_plugin is not installed or force re-install."
        install_plugin $_plugin_id "force"
        _exec_ret_code=$?

        print "Plugin installation status code - $_exec_ret_code"
        if test $_exec_ret_code -eq 0; then
           echo
           print "Plugin ($_plugin) Setup is successful. Querying db for validation...." "GREEN"
           echo

           db_validation $_plugin_id
           _db_validation=$?
           print "Plugin installation DB querying status code - $_db_validation"
           if test $_db_validation -eq 0; then
                  print "$dateAndTime : DB Validation Passed - $_db_validation" "GREEN"
           else
                  print "$dateAndTime : DB Validation Failed - 106" "RED"
                  return 106
           fi

           echo
           print "Plugin ($_plugin) DB Check is successful. Updating ConfigMap...." "GREEN"
           echo

           update_status_in_config_map $CURRENT_FILE $_plugin
           _update_status=$?
           print "Updation of ConfigMap Status Code: $_update_status"
          if test $_update_status -eq 0 ; then
              print "$dateAndTime : ConfigMaps update successfully with status - $_update_status" "GREEN"
              print "SUCCESS: Updated config map."
              return 0
          else
              print "ConfigMaps updation failed with status - 44" "GREEN"
              return 44
          fi
        else
            print "Plugin Setup unsuccessful. "
            return 22
        fi
      fi
    fi
}

install_and_exit_plugin () {
    install_plugin $_plugin_id "force"
    _exec_ret_code=$?
    if test $_exec_ret_code -eq 0; then
      is_plugin_installed $_plugin_id
      _plugin_installation_status=$?
      if test $_plugin_installation_status -eq 0; then
        print "$_plugin upgrade success."
      else
        print "$_plugin upgrade failed."
        exit 1
      fi
    else
      print "$_plugin upgrade failed."
      exit 1
    fi
}

get_plugin_id () {
   plugin=$1

   if [ "$plugin" = "itd" ]; then
      plugin_id="pl_itd_ae"
   else
      plugin_id=$plugin
   fi

   echo $plugin_id
}

get_plugin () {
   plugin_id=$1

   if [ "$plugin_id" = "pl_itd_ae" ]; then
      plugin="itd"
   else
      plugin=$plugin_id
   fi

   echo $plugin
}

_main () {
    if [ "$PPM_DB_VENDOR" = "mssql" ]; then
        print "Skipping plugin installation as DB vendor is mssql"
        return 0
    fi

    # Replace itd plugin with corresponding code
    input_plugins=$(echo "${PPM_PLUGINS//itd/pl_itd_ae}")

    # Input plugins
    plugins=$input_plugins

    if [[ "$PPM_INSTALL_TYPE" == "upgrade" || "$PPM_INSTALL_TYPE" == "patch" ]]; then

        # Accumulated the db plugins and input plugins and remove the unsupported plugins
        admin cd list_plugins -Dinput_plugins=$input_plugins
        # load configuarion file which was genearted as part of above target
        file="/tmp/config.properties"
        if [ -f "$file" ]
        then
            print "$file found."
            source $file
        else
            print "$file not found."
        fi

        # supported_plugins is a key in config.properties and its loaded when file is found
        print "Plugins to be install/upgrade: $supported_plugins"

        # assign input list
        if [[ ! -z $supported_plugins ]]
        then
          plugins=$supported_plugins

          #upgrade plugins in case of upgrade
          print "$PPM_HOME/bin/admin plugin upgrade"
          $PPM_HOME/bin/admin plugin upgrade
      fi
    fi

    if  [ ! -z "$plugins" ]
    then
        for _plugin in ${plugins//,/ }
        do
            echo
            print "----------------- # Plugin Installation - KICKOFF for '$_plugin' START-----------------" "GREEN"
            echo
            install_ppm_plugins $_plugin
            _plugin_status=$?
            if test $_plugin_status -eq 0; then
                print "Plugin Installation - PASSED" "GREEN"
            else
                print "Plugin Installation - FAILED" "RED"
                if [ "$PPM_INSTALL_TYPE" = "upgrade" ]; then
                  exit 1
                else
                  _pod_status=1
                  checkMandatoryOperation
                  is_mandatory=$?
                  if test $is_mandatory -eq 0
                  then
                    print "Mandatory operation failed."
                    return 55
                  fi
                fi
            fi
            echo
            print "----------------- # Plugin Installation - KICKOFF for '$_plugin' END-----------------" "GREEN"
            echo
        done
    else
        print "No input plugins are available to install/upgrade."
    fi
}

echo
print "############################## INITIATED INSTALLATION OF PLUGINS - $PPM_PLUGINS ##############################" "GREEN"
echo
_main
