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

# xz files in directory
# $1 - regexp for files to xz
# "$@" - arguments for xz
backup() {
	local regexp="$1"; shift
	# operate on all files in backup directory that match the given regexp
	find $_BACKUP_DEST -type f -regex "$regexp" -exec xz -z {} \;
}

# xz files in directory
# $1 - regexp for files to xz
# "$@" - arguments for xz
restore() {
	local regexp="$1"; shift
	# operate on all files in backup directory that match the given regexp
	find $_BACKUP_DEST -type f -regex "$regexp\.xz" -exec xz -d {} \;
}
