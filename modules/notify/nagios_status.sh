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

# writes to a file the backup status
# $1 - backup model name
# $2 - backup retval
# $3 - temporary file holding the names of the failed backups
# $4 - status directory
# "$@" - extra parameters from plugin, passed to send_nsca
backup() {
	local backup_model=$1; shift
	local -i backup_retval=$1; shift
	local failed_backups_tmp_file=$1; shift
	local status_dir="$1"; shift

	# if the backup returned with a value greater than zero, we'll just make
	# it a critical value of 2 for nagios
	local message
	if [ $backup_retval -gt 0 ]; then
		backup_retval=2
		message="Critical: Backup failed for: "`cat $failed_backups_tmp_file | xargs`
	else
		message="OK: Backup successful"
	fi

	# create directory
	mkdir -p $status_dir

	# write to file
	echo $message > $status_dir/$backup_model
}

# writes to a file the restore status
# $1 - backup model name
# $2 - backup retval
# $3 - temporary file holding the names of the failed backups
# $4 - status directory
# "$@" - extra parameters from plugin, passed to send_nsca
restore() {
	local backup_model=$1; shift
	local -i backup_retval=$1; shift
	local failed_backups_tmp_file=$1; shift
	local status_dir="$1"; shift

	# if the backup returned with a value greater than zero, we'll just make
	# it a critical value of 2 for nagios
	local message
	if [ $backup_retval -gt 0 ]; then
		backup_retval=2
		message="Critical: Restore failed for: "`cat $failed_backups_tmp_file | xargs`
	else
		message="OK: Restore successful"
	fi

	# create directory
	mkdir -p $status_dir

	# write to file
	echo $message > $status_dir/$backup_model
}
