#!/bin/bash

_validate_required_folders () {
    print "Verifying if required files are present or not...."
    paths_valid=0
    if [[ ! -f "$PPM_HOME/config/logger.xml" ]]
    then
        print "$PPM_HOME/config/logger.xml is not a file."
        paths_valid=1
    fi
    return $paths_valid
}