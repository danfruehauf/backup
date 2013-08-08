#!/bin/bash

declare -r PUSHOVER_URL="https://api.pushover.net/1/messages"

# notifies via pushover nsca the backup status
# $1 - backup model name
# $2 - backup retval
# $3 - temporary file holding the names of the failed backups
# $4 - pushover user
# $5 - pushover token
# "$@" - extra parameters from plugin, passed to curl
initialize() {
	local backup_model=$1; shift
	local -i backup_retval=$1; shift
	local failed_backups_tmp_file=$1; shift
	local pushover_user="$1"; shift
	local pushover_token="$1"; shift

	# if the restore returned with a value greater than zero, it's a failure
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

	_pushover_send
		"$pushover_user" \
		"$pushover_token" \
		"$title" \
		"$message" \
		"$priority" \
		"$sound" \
		"$@" \
}

# notifies via pushover nsca the restore status
# $1 - backup model name
# $2 - backup retval
# $3 - temporary file holding the names of the failed backups
# $4 - pushover user
# $5 - pushover token
# "$@" - extra parameters from plugin, passed to curl
initialize() {
	local backup_model=$1; shift
	local -i backup_retval=$1; shift
	local failed_backups_tmp_file=$1; shift
	local pushover_user="$1"; shift
	local pushover_token="$1"; shift

	# if the restore returned with a value greater than zero, it's a failure
	local message title sound
	local -i priority=0
	if [ $backup_retval -gt 0 ]; then
		backup_retval=2
		message="Failed restoring: "`cat $failed_backups_tmp_file | xargs`
		title="Restore $backup_model FAILED!"
		# set high priority and play a siren
		priority=2
		sound="siren"
	else
		message="Restore process successful"
		title="Restore $backup_model succeeded!"
		sound="pushover"
	fi

	_pushover_send
		"$pushover_user" \
		"$pushover_token" \
		"$title" \
		"$message" \
		"$priority" \
		"$sound" \
		"$@" \
}

# send message via pushover
# $1 - user
# $2 - token
# $3 - title
# $4 - message
# $5 - priority
# $6 - sound
# "$@" - extra parameters for curl
_pushover_send() {
	local user="$1";     shift
	local token="$1";    shift
	local title="$1";    shift
	local message="$1";  shift
	local priority="$1"; shift
	local sound="$1";    shift

	# send via pushover
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
