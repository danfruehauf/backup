#!/bin/bash

# gzips files in directory
# "$@" - arguments for gzip
execute() {
	local regexp="$1"; shift
	# operate on all files in backup directory that match the give regexp
	find $_BACKUP_DEST -type f -regex "$regexp" -exec gzip {} \;
}
