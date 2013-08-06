#!/bin/bash

declare -r PUSHOVER_URL="https://api.pushover.net/1/messages"

# notifies via nagios nsca the backup status
# $1 - backup model name
# $2 - backup retval
# $3 - temporary file holding the names of the failed backups
# $4 - pushover user
# $5 - pushover token
# "$@" - extra parameters from plugin, passed to curl
execute() {
	local backup_model=$1; shift
	local -i backup_retval=$1; shift
	local failed_backups_tmp_file=$1; shift
	local pushover_user="$1"; shift
	local pushover_token="$1"; shift

	# if the backup returned with a value greater than zero, we'll just make
	# it a critical value of 2 for nagios
	local message title sound
	local -i priority=0
	if [ $backup_retval -gt 0 ]; then
		backup_retval=2
		message="Failed backups: "`cat $failed_backups_tmp_file | xargs`
		title="Backup $backup_model FAILED!"
		# set high priority and play a siren
		priority=2
		sound="siren"
	else
		message="All backups good, great success :)"
		title="Backup $backup_model succeeded!"
		sound="pushover"
	fi

	# send via NSCA
	curl \
		-F "user=$pushover_user" \
		-F "token=$pushover_token" \
		-F "title=$title" \
		-F "message=$message" \
		-F "priority=$priority" \
		-F "sound=$sound" \
		"$@" \
		https://api.pushover.net/1/messages
}
