#!/bin/bash

# gzips files in directory
# $1 - regexp for files to gzip
# "$@" - arguments for gzip
execute() {
	local regexp="$1"; shift
	# operate on all files in backup directory that match the given regexp
	find $_BACKUP_DEST -type f -regex "$regexp" -exec gzip {} \;
}
