#!/bin/bash

# Written by Dan Fruehauf <malkodan@gmail.com>

# copies a remote backup using rsync
# usually the backup object name will be the name of the remote host
# $1 - backup path
# "$@" - rsync parameters
backup() {
	local backup_source="$1"; shift
	logger_info "Using rsync to copy backup from '$backup_source'"
	mkdir -p "$_BACKUP_DEST/$_BACKUP_OBJECT_NAME" && \
		rsync -r "$@" "$backup_source" "$_BACKUP_DEST/$_BACKUP_OBJECT_NAME"
}

