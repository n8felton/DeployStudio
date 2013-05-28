#!/bin/sh

# disable history characters
histchars=

echo "ds_add_local_user.sh - v1.14 ("`date`")"

# IMPORTANT NOTE: the script ds_add_local_user.sh script located in the folder Runtime.app/Contents/Resources/Tools/
# is called by DeployStudio Runtime to create the user defined in the hosts database.
# 

# Usage: ds_add_local_user $1 $2 $3 [$4 $5 $6 $7]
# $1 -> realname
# $2 -> shortname
# $3 -> password
# $4 -> admin (YES/NO)
# $5 -> hidden (YES/NO)
# $6 -> localization (English, French, etc...)
# $7 -> uidNumber

# create the default user
NIDB_FILE="/var/db/netinfo/local.nidb"
USER_REALNAME=${1}
USER_SHORTNAME=${2}
USER_PASSWORD=${3}
USER_ADMIN=${4}
USER_HIDDEN=${5}
USER_LOCALE=${6}
USER_UID=${7}

if [ "_YES" == "_${USER_HIDDEN}" ]
then
  USER_HOME="/var/.home/${USER_SHORTNAME}"
  if [ ! -d "/var/.home" ]
  then
    mkdir "/var/.home"
	chown root:admin "/var/.home"
	chmod 775 "/var/.home"
  fi
else
  USER_HOME="/Users/${USER_SHORTNAME}"
fi

if [ ! -e "${NIDB_FILE}" ]
then
  /usr/libexec/create_nidb local localhost /
fi

if [ -n "${USER_SHORTNAME}" ]
then
  SAME_UID="YES"
  if [ -n "${USER_UID}" ]
  then
    SAME_UID=`nicl . -list users uid | awk '{ print "+"$2"+" }' | grep "+${USER_UID}+"`
  fi
  if [ -n "${SAME_UID}" ]
  then
    USER_UID=`nicl . -list users uid | awk '{ print $2 }' | sort -n | tail -n 1`
    USER_UID=`expr ${USER_UID} + 1`
    if [ ${USER_UID} -lt 501 ]
	then
      USER_UID=501
    fi
  fi

  echo "  Creating group '${USER_SHORTNAME}' with gid=${USER_UID} !" 2>&1

  nicl . -delete groups/${USER_SHORTNAME} 2>/dev/null
  nicl . -create groups/${USER_SHORTNAME}

  nicl . -create groups/${USER_SHORTNAME} gid "${USER_UID}"
  nicl . -create groups/${USER_SHORTNAME} passwd "*"

  echo "  Creating user '${USER_SHORTNAME}' with uid=${USER_UID} !" 2>&1

  nicl . -delete users/${USER_SHORTNAME} 2>/dev/null
  nicl . -create users/${USER_SHORTNAME}

  nicl . -create users/${USER_SHORTNAME} uid "${USER_UID}"
  nicl . -create users/${USER_SHORTNAME} gid "${USER_UID}"
  nicl . -create users/${USER_SHORTNAME} sharedDir "Public"
  nicl . -create users/${USER_SHORTNAME} home "${USER_HOME}"
  nicl . -create users/${USER_SHORTNAME} shell "/bin/bash"
  
  if [ -e "/Library/User Pictures/Fun/Gingerbread Man.tif" ]
  then
    nicl . -create users/${USER_SHORTNAME} picture "/Library/User Pictures/Fun/Gingerbread Man.tif"
  else
    if [ -e "/Library/User Pictures/Animals/Butterfly.tif" ]
	then
      nicl . -create users/${USER_SHORTNAME} picture "/Library/User Pictures/Animals/Butterfly.tif"
    fi
  fi
  
  nicl . -create users/${USER_SHORTNAME} _shadow_passwd ""
  nicl . -create users/${USER_SHORTNAME} _writers_passwd "${USER_SHORTNAME}"
  nicl . -create users/${USER_SHORTNAME} _writers_hint "${USER_SHORTNAME}"
  nicl . -create users/${USER_SHORTNAME} _writers_picture "${USER_SHORTNAME}"
  nicl . -create users/${USER_SHORTNAME} _writers_tim_password "${USER_SHORTNAME}"
  nicl . -create users/${USER_SHORTNAME} _writers_realname "${USER_SHORTNAME}"

  nicl . -create users/${USER_SHORTNAME} authentication_authority ";basic;"
  if [ -n "${USER_REALNAME}" ]
  then 
    nicl . -create users/${USER_SHORTNAME} realname "${USER_REALNAME}"
  else
    nicl . -create users/${USER_SHORTNAME} realname "${USER_SHORTNAME}"
  fi

  if [ -n "${USER_PASSWORD}" ]
  then 
    nicl . -create users/${USER_SHORTNAME} passwd `openssl passwd -crypt ${USER_PASSWORD}`
  else
    nicl . -create users/${USER_SHORTNAME} passwd `openssl passwd -crypt ""`
  fi  

  if [ "_YES" = "_${USER_ADMIN}" ]
  then 
	echo "  Setting admin properties" 2>&1
    nicl . -append groups/admin users "${USER_SHORTNAME}"
    
    nicl . -delete users/root generateduid 2>/dev/null
    nicl . -delete users/root authentication_authority 2>/dev/null
    nicl . -delete users/root passwd 2>/dev/null
    nicl . -create users/root authentication_authority ";basic;"
    if [ ! "_" = "_${USER_PASSWORD}" ]
	then 
      nicl . -create users/root passwd `openssl passwd -crypt ${USER_PASSWORD}`
    else
      nicl . -create users/root passwd `openssl passwd -crypt ""`
    fi  
  fi
  
  HOMES_ROOT=`dirname "${USER_HOME}"`
  if [ -d  "${HOMES_ROOT}" ] && [ -d "/System/Library/User Template" ]
  then 
    echo "  Creating local home directory" 2>&1
    if [ -d "/System/Library/User Template/${USER_LOCALE}.lproj" ]
	then
		ditto --rsrc "/System/Library/User Template/${USER_LOCALE}.lproj" "${USER_HOME}"
	else
		ditto --rsrc "/System/Library/User Template/English.lproj" "${USER_HOME}"
	fi
    chown -R ${USER_UID}:${USER_UID} "${USER_HOME}"
  fi
  
  if [ "_YES" == "_${USER_HIDDEN}" ]
  then
	defaults write /Library/Preferences/com.apple.loginwindow HiddenUsersList -array-add "${USER_SHORTNAME}"
	chmod 644 /Library/Preferences/com.apple.loginwindow.plist
	chown root:admin /Library/Preferences/com.apple.loginwindow.plist
  fi
fi
