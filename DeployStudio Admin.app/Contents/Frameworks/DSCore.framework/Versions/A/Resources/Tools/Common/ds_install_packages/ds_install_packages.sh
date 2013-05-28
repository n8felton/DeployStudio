#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SYS_VERS=`sw_vers -productVersion | awk -F. '{ print $2 }'`

echo "${SCRIPT_NAME} - v1.14 ("`date`")"

#
# Export command line installer environment variables
#
export CM_BUILD=CM_BUILD
export COMMAND_LINE_INSTALL=1

#
# Disable assessments checks before installing
#
if [ -e "/usr/sbin/spctl" ]
then
  ASSESSMENTS_CHECKS_ENABLED=`/usr/sbin/spctl --status | grep enabled`
fi

#
# Install the package referenced in /etc/deploystudio/ds_packages/__PACKAGE_INDEX__.idx
#
PACKAGE_INDEX_FILE="/etc/deploystudio/ds_packages/__PACKAGE_INDEX__.idx"
PACKAGE=`cat "${PACKAGE_INDEX_FILE}" | head -n 1`
if [ -e "${PACKAGE}" ]
then
  if [ -n "${ASSESSMENTS_CHECKS_ENABLED}" ]
  then
    /usr/sbin/spctl --master-disable
  fi
  if [ ${SYS_VERS} -gt 6 ]
  then
    INSTALLER_OPTS=-allowUntrusted
  fi
  /usr/sbin/installer -pkg "${PACKAGE}" -target / -verboseR ${INSTALLER_OPTS}
  if [ ${?} -eq 0 ]
  then
    if [ -n "${ASSESSMENTS_CHECKS_ENABLED}" ]
    then
      /usr/sbin/spctl --master-enable
    fi
    echo "Install successful, removing script and related packages..."
    rm -f  "${PACKAGE_INDEX_FILE}"
    rm -rf "${PACKAGE}"

    # Self-removal
    /usr/bin/srm -mf "${0}"
  elif [ "__IGNORE_INSTALL_STATUS__" = "YES" ]
  then
    if [ -n "${ASSESSMENTS_CHECKS_ENABLED}" ]
    then
      /usr/sbin/spctl --master-enable
    fi
    echo "Install failed but this task is configured to ignore failures, removing script and related packages..."
    rm -f  "${PACKAGE_INDEX_FILE}"
    rm -rf "${PACKAGE}"

    # Self-removal
    /usr/bin/srm -mf "${0}"
  else
    if [ -n "${ASSESSMENTS_CHECKS_ENABLED}" ]
    then
      /usr/sbin/spctl --master-enable
    fi
    echo "${PACKAGE} installation failed (referenced in file ${PACKAGE_INDEX_FILE}), will retry on next boot!"
	exit 1
  fi
else
  rm -f "${PACKAGE_INDEX_FILE}"
fi

exit 0