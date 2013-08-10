#!/bin/bash

#
# Copyright (C) 2013 Dan Fruehauf <malkodan@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

# default port for mysql
declare -i -r DEFAULT_MYSQL_PORT=3306

# backup for a mysql database
# $1 - credentials and settings for mysqldump, a colon separated tuple
# "$@" - parameters for mysqldump
backup() {
	# credentials will be in the form of:
	# HOSTNAME:PORT:DB:USERNAME:PASSWORD
	local credentials=$1; shift
	local host=`echo $credentials | cut -d: -f1`
	local -i port=`echo $credentials | cut -d: -f2`
	local name=`echo $credentials | cut -d: -f3`
	local user=`echo $credentials | cut -d: -f4`
	local pass=`echo $credentials | cut -d: -f5-`
	logger_info "MySQL backup initiated with credentials: '$credentials', extra parameters: '$@'"
	[ $port -eq 0 ] && port=$DEFAULT_MYSQL_PORT

	# initiate the backup
	mysqldump -h $host -P $port -u $user -p$pass $name "$@" > "$_BACKUP_DEST/$_BACKUP_OBJECT_NAME".sql
}

# restore for a mysql database
# $1 - credentials and settings for mysql, a colon separated tuple
# "$@" - parameters for mysql
restore() {
	# credentials will be in the form of:
	# HOSTNAME:PORT:DB:USERNAME:PASSWORD
	local credentials=$1; shift
	local host=`echo $credentials | cut -d: -f1`
	local port=`echo $credentials | cut -d: -f2`
	local name=`echo $credentials | cut -d: -f3`
	local user=`echo $credentials | cut -d: -f4`
	local pass=`echo $credentials | cut -d: -f5-`
	logger_info "MySQL restore initiated with credentials: '$credentials', extra parameters: '$@'"

	# initiate the restore
	mysql -h $host -P $port -u $user -p$pass $name "$@" < "$_BACKUP_DEST/$_BACKUP_OBJECT_NAME".sql
}

