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

# TODO hardcoded
declare -r    DEFAULT_EMAIL_HOST=localhost
declare -i -r DEFAULT_EMAIL_PORT=25

# notifies via email
# $1 - backup model name
# $2 - backup retval
# $3 - temporary file holding the names of the failed backups
# $4 - email address
# $5 - email host (using localhost if not specified)
# $6 - email port (using 25 if not specified)
backup() {
	local backup_model=$1; shift
	local -i backup_retval=$1; shift
	local failed_backups_tmp_file=$1; shift
	local email_address="$1"; shift
	local email_host=$1; shift
	local -i email_port=$1; shift

	[ x"$email_host" = x ] && email_host=$DEFAULT_EMAIL_HOST
	[ $email_port -eq 0 ]  && email_port=$DEFAULT_EMAIL_PORT

	local email_subject=""
	local tmp_file_email_content=`mktemp`

	if [ $backup_retval -gt 0 ]; then
		# if the backup failed
		email_subject="Backup failed for '$backup_model'"
		cat > $tmp_file_email_content <<EOF
Sorry mate, unfortunately your backup failed.

Backup model: '$backup_model'

EOF
		echo -n "Backup modules failed: '"   >> $tmp_file_email_content
		cat $failed_backups_tmp_file | xargs >> $tmp_file_email_content
	else
		# if the backup succeeded
		email_subject="Backup succeeded for '$backup_model'"
		cat > $tmp_file_email_content <<EOF
Success! Backup succeeded!

Backup model: '$backup_model'
EOF
	fi

	# and... send the email
	_send_email $email_host $email_port \
		backup@`hostname` $email_address \
		"$email_subject" $tmp_file_email_content

	# remove temporary file
	rm -f $tmp_file_email_content
}

# notifies via email
# $1 - backup model name
# $2 - backup retval
# $3 - temporary file holding the names of the failed backups
# $4 - email address
# $5 - email host (using localhost if not specified)
# $6 - email port (using 25 if not specified)
restore() {
	local backup_model=$1; shift
	local -i backup_retval=$1; shift
	local failed_backups_tmp_file=$1; shift
	local email_address="$1"; shift
	local email_host=$1; shift
	local -i email_port=$1; shift

	[ x"$email_host" = x ] && email_host=$DEFAULT_EMAIL_HOST
	[ $email_port -eq 0 ]  && email_port=$DEFAULT_EMAIL_PORT

	local email_subject=""
	local tmp_file_email_content=`mktemp`

	if [ $backup_retval -gt 0 ]; then
		# if the backup failed
		local email_subject="Restore failed for '$backup_model'"
		cat > $tmp_file_email_content <<EOF
Sorry mate, unfortunately your backup failed.

Backup model: '$backup_model'

EOF
		echo -n "Backup modules failed: '"   >> $tmp_file_email_content
		cat $failed_backups_tmp_file | xargs >> $tmp_file_email_content
	else
		# if the backup succeeded
		cat > $tmp_file_email_content <<EOF
Success! Restore succeeded!

Backup model: '$backup_model'
EOF
	fi

	# and... send the email
	_send_email $email_host $email_port \
		backup@`hostname` $email_address \
		"$email_subject" $tmp_file_email_content

	# remove temporary file
	rm -f $tmp_file_email_content
}

# send an email using nc
# $1 - host
# $2 - port
# $3 - from
# $4 - to
# $5 - subject
# $6 - content file
_send_email() {
	local host=$1; shift
	local -i port=$1; shift
	local from=$1; shift
	local to=$1; shift
	local subject="$1"; shift
	local email_content_file="$1"; shift

	(export smtp=$host:$port; cat $email_content_file | \
		mail -s "$subject" -r $from $to)
}
