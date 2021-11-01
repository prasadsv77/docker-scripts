#!/bin/bash



check_db_health () {
    _health_check_item=$1
    admin cd $_health_check_item -Dinstall.dir=${PPM_HOME} -Drelease=$2
    CMD_RESULT=$?

    if [ $CMD_RESULT -eq 0 ]; then
      return 0
    else
      return 1
    fi
}

check_patch_db_health () {
    _health_check_item=$1
    # admin cd patch-db-status -Dinstalldir=/opt/ppm -Drelease=15.7.1 -Dpatch.version=15.7.1.1.100
    admin cd $_health_check_item -Dinstall.dir=${PPM_HOME} -Drelease=$2 -Dpatch.version=$3
    CMD_RESULT=$?

    if [ $CMD_RESULT -eq 0 ]; then
      return 0
    else
      return 1
    fi
}

check_addin_health () {

    admin cd addin-status -Dinstall.dir=${PPM_HOME} -Drelease=$1 -Daddin=$2
    CMD_RESULT=$?

    if [ $CMD_RESULT -eq 0 ]; then
      return 0
    else
      return 1
    fi
}

check_plugin_health () {

    admin cd plugin-status -Dinstall.dir=${PPM_HOME} -Drelease=$1 -Dplugin=$2
    CMD_RESULT=$?

    if [ $CMD_RESULT -eq 0 ]; then
      return 0
    else
      return 1
    fi
}

check_jasper_ks_health () {

    admin cd jasper-ks-status -Dinstall.dir=${PPM_HOME}
    CMD_RESULT=$?

    if [ $CMD_RESULT -eq 0 ]; then
      return 0
    else
      return 1
    fi
}

check_hdp_health () {

    admin odataservice status
    CMD_RESULT=$?

    if [ $CMD_RESULT -eq 0 ]; then
      return 0
    else
      return 1
    fi
}