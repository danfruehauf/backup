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

# copies a remote backup using rsync
# usually the backup object name will be the name of the remote host
# $1 - backup path
# "$@" - rsync parameters
backup() {
	local backup_source="$1"; shift
	logger_info "Using rsync to copy backup from '$backup_source'"
	mkdir -p "$_BACKUP_DEST/$_BACKUP_OBJECT_NAME" && \
		rsync -r "$@" "$backup_source" "$_BACKUP_DEST/$_BACKUP_OBJECT_NAME"
}

# restore with rsync
# $1 - backup destination
# "$@" - rsync parameters
restore() {
	local backup_source="$1"; shift
	# TODO implement
	# one of the difficulties here is that rsync will not copy the whole
	# hierarchy, so if you backup /etc/passwd, it ends up just as a 'passwd'
	# file and we can't really know how to restore it :/
	# suggest to modify the backup() function to take care of the full path
	# passed, so we actually know how to restore back
	logger_fatal "backup::rsync: Restore functionality unimplemented"
}
