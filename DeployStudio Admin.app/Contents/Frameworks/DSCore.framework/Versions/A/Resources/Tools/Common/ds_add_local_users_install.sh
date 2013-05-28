#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
SCRIPT_PATH=`dirname "${0}"`

echo "${SCRIPT_NAME} - v1.5 ("`date`")"

if [ "${1}" = "/" ]
then
  VOLUME_PATH=/
else
  VOLUME_PATH=/Volumes/${1}
fi

if [ ! -e "${VOLUME_PATH}" ]
then
  echo "RuntimeAbortWorkflow: \"${VOLUME_PATH}\" volume not found!"
  echo "Usage: ${SCRIPT_NAME} <volume name>"
  exit 1
fi

if [ `sw_vers -productVersion | awk -F. '{ print $2 }'` -gt 5 ]
then
  diskutil enableOwnership "${VOLUME_PATH}"
else
  /usr/sbin/vsdbutil -a "${VOLUME_PATH}"
fi

"${SCRIPT_PATH}"/ds_finalize_install.sh "${1}"

cp "${SCRIPT_PATH}"/ds_add_local_users/ds_add_local_users_main.sh "${VOLUME_PATH}"/etc/deploystudio/bin
cp "${SCRIPT_PATH}"/ds_add_local_users/ds_add_local_user.sh "${VOLUME_PATH}"/etc/deploystudio/bin
chmod 700 "${VOLUME_PATH}"/etc/deploystudio/bin/ds_add_local_users_main.sh "${VOLUME_PATH}"/etc/deploystudio/bin/ds_add_local_user.sh
chown root:wheel "${VOLUME_PATH}"/etc/deploystudio/bin/ds_add_local_users_main.sh "${VOLUME_PATH}"/etc/deploystudio/bin/ds_add_local_user.sh

#"${SCRIPT_PATH}"/../Common/ds_enable_verbose_reboot.sh "${1}"

echo "${SCRIPT_NAME} - end"

exit 0
