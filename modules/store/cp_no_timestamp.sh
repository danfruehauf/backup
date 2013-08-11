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

# copies backup with cp
# $1 - backup destination
# "$@" - cp parameters
backup() {
	local backup_destination="$1"; shift

	logger_info "Using cp to copy backup to '$backup_destination'"
	mkdir -p "$backup_destination" && \
		cp -a "$@" $_BACKUP_DEST/* "$backup_destination"
}

# copies backup with cp
# $1 - backup destination
# "$@" - rsync parameters
restore() {
	local backup_destination="$1"; shift

	# copy last backup to the restoration directory
	logger_info "Using cp to copy backup from '$backup_destination/$last_backup'"
	cp -a "$@" $backup_destination/$last_backup/* $_BACKUP_DEST/
}

