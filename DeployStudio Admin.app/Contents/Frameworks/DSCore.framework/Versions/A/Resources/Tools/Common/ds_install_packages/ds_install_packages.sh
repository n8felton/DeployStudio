#!/bin/sh

SCRIPT_NAME=`basename "${0}"`

echo "${SCRIPT_NAME} - v1.12 ("`date`")"

#
# Export command line installer environment variables
#
export CM_BUILD=CM_BUILD
export COMMAND_LINE_INSTALL=1

#
# Install the package referenced in /etc/deploystudio/ds_packages/__PACKAGE_INDEX__.idx
#
PACKAGE_INDEX_FILE="/etc/deploystudio/ds_packages/__PACKAGE_INDEX__.idx"
PACKAGE=`cat "${PACKAGE_INDEX_FILE}" | head -n 1`
if [ -e "${PACKAGE}" ]
then
  /usr/sbin/installer -pkg "${PACKAGE}" -target / -verboseR
  if [ ${?} -eq 0 ]
  then
    echo "Install successful, removing script and related packages..."
    rm -f  "${PACKAGE_INDEX_FILE}"
    rm -rf "${PACKAGE}"

    # Self-removal
    /usr/bin/srm -mf "${0}"
  elif [ "__IGNORE_INSTALL_STATUS__" = "YES" ]
  then
    echo "Install failed but this task is configured to ignore failures, removing script and related packages..."
    rm -f  "${PACKAGE_INDEX_FILE}"
    rm -rf "${PACKAGE}"

    # Self-removal
    /usr/bin/srm -mf "${0}"
  else
    echo "${PACKAGE} installation failed (referenced in file ${PACKAGE_INDEX_FILE}), will retry on next boot!"
	exit 1
  fi
else
  rm -f "${PACKAGE_INDEX_FILE}"
fi

exit 0