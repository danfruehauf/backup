#!/bin/bash

# leave only $backups_to_leave backup files in $directory
# $1 - directory
# $2 - backups_to_leave
backup() {
	local directory=$1; shift
	local -i backups_to_leave=$1; shift
	[ $backups_to_leave -eq 0 ] && \
		logger_fatal "Do you really want to leave 0 backups in '$directory'?"

	if [ x"$directory" = x ] || [ "$directory" = "/" ]; then
		echo "directory '$directory' is invalid!!"
		return 1
	fi
	local -i total_backups=`ls -1 $directory | wc -l`
	local -i backups_to_remove=`expr $total_backups - $backups_to_leave`
	if [ $backups_to_remove -gt 0 ]; then
		logger_info "Removing '$backups_to_remove' backups in '$directory'"
		(cd $directory && ls -1td */ | tail -$backups_to_remove | xargs rm --preserve-root -rf)
	fi
}

# not really implemented for cycle, just return 1, so we signal we didn't find
# any backup
restore() {
	return 1
}
