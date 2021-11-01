#!/bin/bash
CURRENT_FILE="$(basename "${BASH_SOURCE[0]}")"

perform_pre_check () {

    if [ "$PPM_SYSTEM_ENVIRONMENT" = "OD" ]; then
        _environment_type="TARGET"
    else
        _environment_type="OP"
    fi
    print $PPM_HOME/bin/admin cd pre_check -Dcheckinstall_dir=$CHECKINSTALL_HOME -Dtarget.environment.type=$_environment_type -Doperation=$PPM_INSTALL_TYPE
    $PPM_HOME/bin/admin cd pre_check -Dcheckinstall_dir=$CHECKINSTALL_HOME -Dtarget.environment.type=$_environment_type -Doperation=$PPM_INSTALL_TYPE
    _command_status=$?
    if test $_command_status -ne 0; then
        print "Pre check validation has failed." "RED"
        print "Pushing results xml file to logs folder."
        pre_check_logs
       return 1
    else
      print "Pre check validation has passed."
      print "Pushing results xml file to logs folder."
      pre_check_logs
    fi
}

perform_post_check () {

    if [ "$PPM_SYSTEM_ENVIRONMENT" = "OD" ]; then
        _environment_type="TARGET"
    else
        _environment_type="OP"
    fi
    print $PPM_HOME/bin/admin cd post_check -Dcheckinstall_dir=$CHECKINSTALL_HOME -Dtarget.environment.type=$_environment_type -Doperation=$PPM_INSTALL_TYPE
    $PPM_HOME/bin/admin cd post_check -Dcheckinstall_dir=$CHECKINSTALL_HOME -Dtarget.environment.type=$_environment_type -Doperation=$PPM_INSTALL_TYPE
    _command_status=$?
    if test $_command_status -ne 0; then
        print "Post check validation has failed." "RED"
        print "Pushing results xml file to logs folder."
        post_check_logs
       return 1
    else
      print "Post check validation has passed."
      print "Pushing results xml file to logs folder."
      post_check_logs
    fi
}


pre_check_logs () {
  push_check_logs $CHECKINSTALL_HOME/check-logs/checkinstall.log $PPM_HOME/logs/$CONTAINER_METADATA_INFO-checkinstall.log
  push_check_logs $CHECKINSTALL_HOME/check-logs/precheck-results.xml $PPM_HOME/logs/$CONTAINER_METADATA_INFO-precheck-results.xml
  _result_file_pushed=$?
  if test $_result_file_pushed -ne 0; then
    print "Failed to push precheck-result.xml file" "RED"
    exit 1
  else
    print "Pushed precheck-result.xml file to path: $PPM_HOME/logs/$CONTAINER_METADATA_INFO-precheck-results.xml"
  fi
}

post_check_logs () {
  push_check_logs $CHECKINSTALL_HOME/check-logs/checkinstall.log $PPM_HOME/logs/$CONTAINER_METADATA_INFO-checkinstall.log
  push_check_logs $CHECKINSTALL_HOME/check-logs/invalid_nsql_queries.txt $PPM_HOME/logs/$CONTAINER_METADATA_INFO-invalid_nsql_queries.txt
  push_check_logs $CHECKINSTALL_HOME/check-logs/postcheck-results.xml $PPM_HOME/logs/$CONTAINER_METADATA_INFO-postcheck-results.xml
  _result_file_pushed=$?
  if test $_result_file_pushed -ne 0; then
    print "Failed to push postcheck-result.xml file" "RED"
    exit 1
  else
    print "Pushed postcheck-result.xml file to path: $PPM_HOME/logs/$CONTAINER_METADATA_INFO-postcheck-results.xml"
  fi
}

push_check_logs () {
  _src_file_path=$1
  _dest_file_path=$2
  if [ -f $_src_file_path ]; then
      print "pushing $2 file to logs folder. "
      cp $_src_file_path $_dest_file_path
  else
    print "File path $_src_file_path does not exist"
    return 1
  fi
}