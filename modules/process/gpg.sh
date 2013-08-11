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

# suffix to add to files encrypted with gpg
declare -r GPG_SUFFIX=gpg

# encrypts files with gpg
# $1 - regexp for files to encrypt with gpg
# $2 - key file to encrypt with
backup() {
	local regexp="$1"; shift
	local key_file=$1; shift

	[ x"$key_file" = x ] && logger_fatal "Didn't specify key file for gpg encryption"
	[ ! -f $key_file ] && logger_fatal "Key file '$key_file' doesn't exist"

	# import key
	local tmp_gpg_homedir=`mktemp -d`
	if ! _import_gpg_key $tmp_gpg_homedir $key_file; then
		logger_fatal "Failed to import gpg key '$tmp_keyring'"
	fi

	# get the key id, this is the recipient field when encrypting
	local key_id=`gpg --homedir $tmp_gpg_homedir --list-keys | \
		grep '^pub\b' | tr -s " " | cut -d' ' -f2 | cut -d/ -f2`

	# bail on any error here...
	set -e

	# operate on all files in backup directory that match the given regexp
	local file
	for file in `find $_BACKUP_DEST -type f -regex "$regexp"`; do
		# encrypt with gpg
		gpg --homedir $tmp_gpg_homedir \
			--batch -q --yes \
			--trust-model always --encrypt \
			--recipient $key_id \
			--output $file.$GPG_SUFFIX $file

		# preserve permissions of file after encryption
		chown --reference=$file $file.$GPG_SUFFIX
		chmod --reference=$file $file.$GPG_SUFFIX

		# remove the old file
		rm -f $file
	done
	set +e

	rm -rf --preserve-root $tmp_gpg_homedir
}

# decrypts files with gpg
# $1 - regexp for files to descypt with gpg
# $2 - key file to decrypt with
restore() {
	# TODO implement
	logger_fatal "process::gpg: Restore functionality unimplemented"
}

# imports a gpg key
# $1 - gpg temporary homedir
_import_gpg_key() {
	local gpg_homedir=$1; shift
	local key_file=$1; shift
	gpg --homedir $gpg_homedir --import $key_file
}
