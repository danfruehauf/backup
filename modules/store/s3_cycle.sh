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

# leave only $backups_to_leave backup files in $directory
# $1 - directory
# $2 - backups_to_leave
backup() {
	local bucket_name=$1; shift
	local -i backups_to_leave=$1; shift
	[ $backups_to_leave -eq 0 ] && \
		logger_fatal "Do you really want to leave 0 backups in 's3://$bucket_name'?"

	if [ x"$bucket_name" = x ]; then
		echo "Bucket is undefined!!"
		return 1
	fi

	local tmp_bucket_contents=`mktemp`
	s3cmd "$@" ls s3://$bucket_name | tr -s " " | cut -d' ' -f3 | sort -r >& $tmp_bucket_contents
	local -i total_backups=`cat $tmp_bucket_contents | wc -l`

	if [ $total_backups -eq 0 ]; then
		logger_warn "Error listing contents or no content in bucket 's3://$bucket_name'"
		rm -f $tmp_bucket_contents
		return 1
	fi

	local -i backups_to_remove=`expr $total_backups - $backups_to_leave`
	if [ $backups_to_remove -gt 0 ]; then
		logger_info "Removing '$backups_to_remove' backups in bucket 's3://$bucket_name'"
		local backup_to_remove
		for backup_to_remove in `tail -q -n $backups_to_remove $tmp_bucket_contents`; do
			logger_info "Removing '$backup_to_remove'"
			s3cmd "$@" --recursive del $backup_to_remove
		done
	fi

	rm -f $tmp_bucket_contents
}

# not really implemented for cycle, just return 1, so we signal we didn't find
# any backup
restore() {
	return 1
}
