#!/bin/bash
CURRENT_FILE="$(basename "${BASH_SOURCE[0]}")"
source $PPM_HOME_SCRIPTS/healthcheck/dbhealthcheck.sh

db_validation (){
    _add_in_passed=$1
    print "DB validation for addin : $_add_in_passed"
    check_addin_health $CLARITY_RELEASE $_add_in_passed
    _db_check=$?
    return $_db_check
}

install_addin (){
  print "Installing PPM Addin $1"
  echo
  print "PPM_HOME/bin/admin content $1"
  $PPM_HOME/bin/admin content $1
}

is_addin_installed (){
   db_validation $1
   _db_validation=$?
   print "Addin installation DB querying status code - $_db_validation"
   if test $_db_validation -eq 0; then
      print "DB Validation Passed - $_db_validation" "GREEN"
   else
      print "DB Validation Failed - 106" "RED"
      return 106
   fi
}

install_ppm_addins () {
    _addin=$1
    print "checking in config map if $_addin add in is already installed"
    check_status_in_config_map $CURRENT_FILE $_addin
    _addin_config_status=$?
    if test $_addin_config_status -eq 0; then
      if [ "$PPM_INSTALL_TYPE" = "upgrade" ]; then

        # check whether addin is already up-to-date with latest version
        is_addin_installed $_addin > /dev/null # do not print/capture logs, in case of failure we need to proceed to install.
        _db_validation=$?
        if test $_db_validation -eq 0; then
          print "$_addin is already upgraded to $CLARITY_RELEASE" "GREEN"
        else
          # Proceed installation if version mismatch
          install_addin $_addin
          _exec_ret_code=$?
          if test $_exec_ret_code -eq 0; then
            is_addin_installed $_addin
            _addin_installation_status=$?
            if test $_addin_config_status -eq 0; then
              print "$_addin upgrade success"
            else
              print "$_addin upgrade failed"
              exit 1
            fi
          else
            print "$_addin upgrade failed"
            exit 1
          fi
        fi
      else
        print "Add in $_addin is already installed."
        return 0
      fi
    else
        print "Add in $_addin is not yet installed."
        install_addin $_addin
        _exec_ret_code=$?

        print "Addin installation status code - $_exec_ret_code"
        if test $_exec_ret_code -eq 0; then

             db_validation $_addin
             _db_validation=$?
             print "Addin installation DB querying status code - $_db_validation"
             if test $_db_validation -eq 0; then
                    print "$dateAndTime : DB Validation Passed - $_db_validation" "GREEN"
             else
                    print "$dateAndTime : DB Validation Failed - 106" "RED"
                    return 106
             fi

             echo
             print "Addin ($_addin) DB Check is successful. Updating ConfigMap...." "GREEN"
             echo

             update_status_in_config_map $CURRENT_FILE $_addin
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
            print "DB Setup unsuccessful. "
            return 22
        fi
    fi
}

check_and_install_addin_demodata () {
    print "checking if demodata is requested for $_addin"
    _addin=$1
    _demodata_install_success=0
    if [[ $PPM_ADDINS_DEMODATA == *$_addin* ]]; then
      check_addin_health "$CLARITY_RELEASE" "$_addin"::demo > /dev/null
      _is_demodata_installed=$?

      if test $_is_demodata_installed -ne 0; then
        install_addin_demodata $_addin
        _demodata_install_success=$?
      else
        print "Demodata for $_addin already installed..Skipping demodata setup"
      fi
    fi
    return $_demodata_install_success
}

install_addin_demodata () {
    _addin=$1
    echo
    print "----------------- # Addin Demodata Installation - KICKOFF for '$_addin' START-----------------" "GREEN"
    echo
    $PPM_HOME/bin/admin content-demo $_addin
    _exec_ret_code=$?
    print "Addin $_addin demodata installation status code - $_exec_ret_code"

    if test $_exec_ret_code -eq 0; then
      print "Addin Demodata Installation - PASSED" "GREEN"
    else
      print "Addin Demodata Installation - FAILED" "RED"
    fi

    echo
    print "----------------- # Addin Demodata Installation - KICKOFF for '$addin' END-----------------" "GREEN"
    echo
    return $_exec_ret_code
}

_main () {

    # input addins
    addins=$PPM_ADDINS

    if [[ "$PPM_INSTALL_TYPE" == "upgrade" || "$PPM_INSTALL_TYPE" == "patch" ]]; then
        # Accumulated the db addins and input addins and remove the unsupported addins
        admin cd list_addins -Dinput_addins=$PPM_ADDINS
        # load configuarion file which was genearted as part of above target
        file="/tmp/config.properties"
        if [ -f "$file" ]
        then
            print "$file found."
            source $file
        else
            print "$file not found."
        fi

        # supported_addins is a key in config.properties and its loaded when file is found
        print "Addins to be install/upgrade: $supported_addins"

        # assign input list
        if [ ! -z $supported_addins ]
        then
          addins=$supported_addins
        fi
    fi

    if  [ ! -z "$addins" ]
    then
        for addin in ${addins//,/ }
        do
            echo
            print "----------------- # Addin Installation - KICKOFF for '$addin' START-----------------" "GREEN"
            echo
            install_ppm_addins $addin
            _addin_status=$?
            if test $_addin_status -eq 0; then
                print "Addin Installation - PASSED" "GREEN"
                check_and_install_addin_demodata $addin
            else
                print "Addin Installation - FAILED" "RED"
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
            print "----------------- # Addin Installation - KICKOFF for '$addin' END-----------------" "GREEN"
            echo
        done
    else
        print "No addins are available to install/upgrade."
    fi
}

echo 
print "############################## INITIATED INSTALLATION OF ADDINS - $PPM_ADDINS ##############################" "GREEN"
echo 
_main
