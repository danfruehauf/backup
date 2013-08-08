#!/bin/bash

# gzips files in directory
# $1 - regexp for files to gzip
# "$@" - arguments for gzip
backup() {
	local regexp="$1"; shift
	# operate on all files in backup directory that match the given regexp
	find $_BACKUP_DEST -type f -regex "$regexp" -exec gzip {} \;
}

# gunzips files in directory
# $1 - regexp for files to gunzip
# "$@" - arguments for gunzip
restore() {
	local regexp="$1"; shift
	# operate on all files in backup directory that match the given regexp
	find $_BACKUP_DEST -type f -regex "$regexp\.gz" -exec gunzip {} \;
}
