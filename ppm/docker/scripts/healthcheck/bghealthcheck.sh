#!/bin/bash


RESULT=$( ps aux | grep -i "[s]erviceId=bg" | wc -l )
  if [ $RESULT -eq 1 ];then
     echo "bg health check is successful"
     exit 0
  else
     echo "bg health check is failed"
     exit 1
  fi


