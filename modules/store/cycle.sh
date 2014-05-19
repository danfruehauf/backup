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

# leave only $backups_to_leave backup files in given $directory_pattern
# can provide wildcard directories
# $1 - directory pattern
# $2 - backups_to_leave
backup() {
	local directory_pattern="$1"; shift
	local -i backups_to_leave=$1; shift
	[ $backups_to_leave -eq 0 ] && \
		logger_fatal "Do you really want to leave 0 backups in '$directory'?"

	for directory in $directory_pattern; do
		if [ x"$directory" = x ] || [ "$directory" = "/" ]; then
			echo "directory '$directory' is invalid!!"
			return 1
		fi

		if [ -d "$directory" ]; then
			logger_info "Cycling directory '$directory'"
			local -i total_backups=`ls -1 $directory | wc -l`
			local -i backups_to_remove=`expr $total_backups - $backups_to_leave`
			if [ $backups_to_remove -gt 0 ]; then
				logger_info "Removing '$backups_to_remove' backups in '$directory'"
				(cd $directory && ls -1td */ | tail -$backups_to_remove | xargs rm --preserve-root -rf)
			fi
		fi
	done
}

# not really implemented for cycle, just return 1, so we signal we didn't find
# any backup
restore() {
	return 1
}
