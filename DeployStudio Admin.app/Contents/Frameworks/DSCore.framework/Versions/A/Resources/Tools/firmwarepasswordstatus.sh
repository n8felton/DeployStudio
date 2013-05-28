#!/bin/sh

VERSION=1.0

SETREGPROPTOOL=`dirname "${0}"`/setregproptool 

if [ -e "${SETREGPROPTOOL}" ] && [ ! `/usr/bin/arch` = "ppc" ]
then
  "${SETREGPROPTOOL}" -c
  if [ ${?} -eq 0 ]
  then
    echo "status: on"
    exit 0
  fi
fi

echo "status: off"

exit 0
