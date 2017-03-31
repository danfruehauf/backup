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

# spools backup to s3
# $1 - bucket name
# "$@" - extra s3 parameters
backup() {
	local bucket_name="$1"; shift

	backup_key_timestamp=`_generate_date`

	logger_info "Spooling backup to S3 bucket 's3://$bucket_name/$backup_key_timestamp'"
	s3cmd "$@" --recursive put $_BACKUP_DEST/* s3://$bucket_name/$backup_key_timestamp/
}

# pulls backups from s3 (latest backup)
# $1 - bucket name
# "$@" - extra s3 parameters
restore() {
	local bucket_name="$1"; shift

	local latest_backup
	latest_backup=`s3cmd "$@" ls s3://$bucket_name/ | tr -s " " | cut -d' ' -f3 | sort | tail -1`
	if [ $? -ne 0 ]; then
		logger_fatal "No backups found in 's3://$bucket_name/'"
	fi

	logger_info "Latest backup in bucket is '$latest_backup'"

	# pull latest backup
	logger_info "Pulling backup from S3 bucket '$latest_backup'"
	s3cmd "$@" --recursive get $latest_backup $_BACKUP_DEST/
}
