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
	# simply create a tar archive
	logger_info "Creating tar archive with parameters '$@'"
	(cd / && tar -cf $_BACKUP_DEST/$_BACKUP_OBJECT_NAME.tar "$@")
}

# untar
# "$@" - arguments for tar, usually it'll be the filename to untar
restore() {
	# restore tar archive
	logger_info "Untarring with parameters '$@'"
	(cd / && tar -xf $_BACKUP_DEST/$_BACKUP_OBJECT_NAME.tar)
}
