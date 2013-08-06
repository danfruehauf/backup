#!/bin/bash

# notifies via nagios nsca the backup status
# $1 - backup model name
# $2 - backup retval
# $3 - temporary file holding the names of the failed backups
# $4 - nagios monitor name
# "$@" - extra parameters from plugin, passed to send_nsca
execute() {
	local backup_model=$1; shift
	local -i backup_retval=$1; shift
	local failed_backups_tmp_file=$1; shift
	local nagios_monitor_name="$1"; shift

	# if the backup returned with a value greater than zero, we'll just make
	# it a critical value of 2 for nagios
	local nsca_verbose_message
	if [ $backup_retval -gt 0 ]; then
		backup_retval=2
		nsca_verbose_message="Failed backups: "`cat $failed_backups_tmp_file | xargs`
	else
		nsca_verbose_message="All backups good"
	fi

	# format nsca message
	local formatted_nsca_message=`hostname`";$nagios_monitor_name;$backup_retval;$nsca_verbose_message"

	# send via nsca
	echo $formatted_nsca_message | /usr/sbin/send_nsca -d';' "$@"
}
