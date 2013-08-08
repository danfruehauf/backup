#!/bin/bash

# Written by Dan Fruehauf <malkodan@gmail.com>

# copies backup with rsync
# $1 - backup destination
# "$@" - rsync parameters
backup() {
	local backup_name=$1; shift
	local scp_destination=$1; shift
	local backup_destination="$scp_destination/$backup_name-"`_generate_date`
	logger_info "Using scp to copy backup to '$backup_destination'"
	scp -r "$@" -o NumberOfPasswordPrompts=0 $_BACKUP_DEST "$backup_destination"
}

