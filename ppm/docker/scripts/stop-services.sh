#!/bin/bash

set_orchestration_metadata() {
  source $PPM_HOME_SCRIPTS/populate-container-metadata.sh
}

stop() {
  print "Triggered shutdown services..."
  $PPM_HOME/bin/service stop all
}

_main() {
  set_orchestration_metadata
  stop
}

_main