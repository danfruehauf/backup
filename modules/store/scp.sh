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

# copies backup with scp
# $1 - backup destination
# "$@" - rsync parameters
backup() {
	local backup_name=$1; shift
	local scp_destination=$1; shift
	local backup_destination="$scp_destination/$backup_name-"`_generate_date`
	logger_info "Using scp to copy backup to '$backup_destination'"
	scp -r "$@" -o NumberOfPasswordPrompts=0 $_BACKUP_DEST "$backup_destination"
}

# retrieves backup with scp for restoration
# $1 - backup destination
# "$@" - rsync parameters
restore() {
	local backup_name=$1; shift
	local scp_destination=$1; shift
	local backup_destination="$scp_destination/$backup_name-"`_generate_date`
	# TODO implement
	logger_fatal "backup::scp: Restore functionality unimplemented"
}
