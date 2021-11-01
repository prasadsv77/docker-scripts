#!/bin/bash
# Script to check activemq master/slave process

mastercheck=`netstat -nap|grep 61616|grep LISTEN`
slavecheck=`ps -aux | grep activemq | grep -v grep`
slavelog=`tac /usr/share/activemq/data/activemq.log |head -1|grep "slave mode waiting"`


## Check master process and return 0 if running
if [ -n "$mastercheck" ]; then
   exit 0
## Check slave process and return 0 if running
elif [[ -n "$slavecheck" ]] && [[ -n "$slavelog" ]]; then
   exit 0
## Return 1 if nothing is running
else
   exit 1
fi