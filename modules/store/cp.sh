#!/bin/bash

# Written by Dan Fruehauf <malkodan@gmail.com>

# copies backup with cp
# $1 - backup destination
# "$@" - cp parameters
backup() {
	local backup_destination="$1/"`_generate_date`; shift
	logger_info "Using cp to copy backup to '$backup_destination'"
	mkdir -p "$backup_destination" && \
		cp -a "$@" $_BACKUP_DEST/* "$backup_destination"
}

# copies backup with cp
# $1 - backup destination
# "$@" - rsync parameters
restore() {
	local backup_destination="$1"; shift

	# select last backup in $backup_destination
	local last_backup
	last_backup=`ls -1tr $backup_destination | tail -1`
	if [ $? -ne 0 ]; then
		logger_fatal "No backups found in '$backup_destination'"
	fi

	# copy last backup to the restoration directory
	logger_info "Using cp to copy backup from '$backup_destination/$last_backup'"
	cp -a "$@" $backup_destination/$last_backup/* $_BACKUP_DEST/
}

