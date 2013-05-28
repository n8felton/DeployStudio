#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.0

if [ ${#} -lt 1 ]
then
  echo "Usage: ${SCRIPT_NAME} <volume path>"
  echo "Example: ${SCRIPT_NAME} /Volumes/Macintosh\ HD"
  exit 1
fi

echo "Running ${SCRIPT_NAME} v${VERSION}"

if [ -e "${1}" ]
then

  WORKDIR=`dirname "${0}"`
  SYS_VERSION=`sw_vers -productVersion | cut -c 4`
  
  if [ ${SYS_VERSION} -gt 4 ]
  then
    echo "post-10.4 system, aborting..."
  else
    echo "pre-10.5 system, using SetHidden binary..."
    "${WORKDIR}"/SetHidden "${1}" "${WORKDIR}"/HiddenFiles.txt
  fi

fi

echo "Exiting ${SCRIPT_NAME} v${VERSION}"

exit 0
