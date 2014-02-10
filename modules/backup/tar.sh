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

# tars arguments
# "$@" - arguments for tar, usually it'll be filenames
backup() {
	local sudo=""
	if _sudo "$@"; then
		shift # remove the argument
		local sudo="sudo"
	fi

	# simply create a tar archive
	logger_info "Creating tar archive with parameters '$@'"
	(cd / && $sudo tar -cf $_BACKUP_DEST/$_BACKUP_OBJECT_NAME.tar "$@")
}

# untar
# "$@" - arguments for tar, usually it'll be the filename to untar - unused!!
restore() {
	local sudo=""
	if _sudo "$@"; then
		shift # remove the argument
		local sudo="sudo"
	fi

	# restore tar archive
	logger_info "Untarring with parameters '$@'"
	(cd / && $sudo tar -xf $_BACKUP_DEST/$_BACKUP_OBJECT_NAME.tar)
}

# returns 0 if --sudo is set, 1 otherwise
# "$@" - arguments for tar, will parse --sudo
_sudo() {
	[ x"$1" != x ] && [ "$1" = "--sudo" ] && return 0
	return 1
}
