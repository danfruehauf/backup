#!/bin/bash

# Written by Dan Fruehauf <malkodan@gmail.com>

# backup for a mysql database
# $1 - credentials and settings for mysqldump, a colon separated tuple
# "$@" - parameters for mysqldump
execute() {
	# credentials will be in the form of:
	# HOSTNAME:PORT:DB:USERNAME:PASSWORD
	local credentials=$1; shift
	local host=`echo $credentials | cut -d: -f1`
	local port=`echo $credentials | cut -d: -f2`
	local name=`echo $credentials | cut -d: -f3`
	local user=`echo $credentials | cut -d: -f4`
	local pass=`echo $credentials | cut -d: -f5-`
	logger_info "MySQL backup initiated with credentials: '$credentials', extra parameters: '$@'"

	local -i retval
	mysqldump -h $host -P $port -u $user -p$pass $name "$@" > "$_BACKUP_DEST/$_BACKUP_OBJECT_NAME".sql
}

