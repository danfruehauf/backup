#!/bin/bash

# Written by Dan Fruehauf <malkodan@gmail.com>

# copies backup with rsync
# $1 - backup destination
# "$@" - rsync parameters
execute() {
	local backup_destination="$1/"`date '+%Y.%m.%d.%H.%m.%S'`; shift
	logger_info "Using cp to copy backup to '$backup_destination'"
	mkdir -p "$backup_destination" && \
		cp -a "$@" $_BACKUP_DEST/* "$backup_destination"
}

