#!/bin/bash

# Written by Dan Fruehauf <malkodan@gmail.com>

# damn crontab runs without environment
# at least get a proper PATH if running from cron
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# global variable to keep all log facilities registered
# P.S. i hate global variables
LOG_FACILITIES=""

# logs an info message
# "$@" - message to log
logger_info() {
	_logger info "$@"
}

# logs a warning message
# "$@" - message to log
logger_warn() {
	_logger warn "$@"
}

# logs a fatal message and exits
# "$@" - message to log
logger_fatal() {
	_logger fatal "$@"
	exit 2
}

# logs a message
# "$@" - message to log
_logger() {
	local log_level=$1; shift
	local msg="["`date`"] $@"

	# log to all facilities
	IFS=$'\n'
	local log_facility
	for log_facility in $LOG_FACILITIES; do
		unset IFS
		local logger_module=`echo $log_facility | cut -d' ' -f1`
		local logger_params=`echo $log_facility | cut -d' ' -f2-`
		(source $MODULES_DIR/log/$logger_module.sh && echo $msg | execute $log_level $logger_params)
	done
	echo $msg
}

# handle backup section in backup model
# $1 - backup model file
# $2 - tmp backup directory
# $3 - module to run
_backup() {
	local backup_model=$1; shift
	local tmp_backup_dir=$1; shift
	local module=$1; shift

	# backup/context name, will usually be used as a subdirectory in the
	# module
	local backup_object_name=$1; shift

	# execute module in subshell, to not contaminate environment
	(source $MODULES_DIR/backup/$module.sh && \
		export _BACKUP_DEST=$tmp_backup_dir && \
		export _BACKUP_OBJECT_NAME=$backup_object_name && \
		execute "$@")
}

# handle store section in backup model
# $1 - backup model file
# $2 - tmp backup directory
# $3 - module to run
_store() {
	local backup_model=$1; shift
	local tmp_backup_dir=$1; shift
	local module=$1; shift
	# execute module in subshell, to not contaminate environment
	(source $MODULES_DIR/store/$module.sh && \
		export _BACKUP_DEST=$tmp_backup_dir && \
		execute "$@")
}

# handle notify section in backup model
# $1 - backup model file
# $2 - return value of backup
# $3 - temporary file holding the names of the failed backups
# "$@" - extra plugin parameters
_notify() {
	local backup_model=$1; shift
	local -i backup_retval=$1; shift
	local failed_backups_tmp_file=$1; shift

	# first parameter after should be the module to run
	local module=$1; shift

	# we are interested only in the name
	backup_model=`basename $backup_model`

	# execute module in subshell, to not contaminate environment
	(source $MODULES_DIR/notify/$module.sh && \
		execute $backup_model $backup_retval $failed_backups_tmp_file "$@")
}

# gets all the commands for a specific model
# $1 - backup_model file
# $2 - type (log, backup, notify, etc)
get_commands() {
	local backup_model=$1; shift
	local mod_type=$1; shift
	# use some sed to return things in a pretty way
	(source $backup_model && \
		declare -f $mod_type >& /dev/null && \
		declare -f $mod_type | \
		sed -e '1,2d' -e '$d' -e '/^#/d' -e 's/;$//g' -e 's#^\s\+##g')
}

# executes a single backup model
# $1 - backup model
execute_backup() {
	local backup_model="$1"; shift
	test -f "$backup_model" || logger_fatal "Backup model '$backup_model' does not exist"
	logger_info "Executing backup model '"`basename $backup_model`"'"

	# set the backup name
	backup_name=`basename $backup_model`

	local tmp_backup_dir=`mktemp -d`
	logger_info "Temp directory for backup is '$tmp_backup_dir'"
	local -i retval=0

	# initialize loggers in the global variables LOG_FACILITIES, separated by
	# new lines :)
	IFS=$'\n'
	for command in `get_commands $backup_model log`; do
		unset IFS
		LOG_FACILITIES="$LOG_FACILITIES
$command"
	done

	# iterate on backup and store sections
	local failed_backups
	local succeeded_backups
	IFS=$'\n'
	for step in backup store; do
		IFS=$'\n'
		for command in `get_commands $backup_model $step`; do
			unset IFS
			local module=`echo $command | cut -d' ' -f1`
			local module_parameters=`echo $command | cut -d' ' -f2-`
			logger_info "Executing module '$step::$module' with parameters '$module_parameters'"
			# execute step, which will apply it's logic
			# run with eval, so module_parameters is passed as multiple parameters
			# call backup() step
			eval _$step $backup_model $tmp_backup_dir $module $module_parameters
			if [ $? -ne 0 ]; then
				logger_warn "Module '$step::$module' failed :("
				local failed_backups="$failed_backups '$step::$module'"
				let retval=$retval+1
			else
				logger_info "Module '$step::$module' was successful :)"
				local succeeded_backups="$succeeded_backups '$step::$module'"
			fi
		done
	done

	# cleanup temporary backup directory
	rm -rf $tmp_backup_dir

	# call notify plugins
	IFS=$'\n'
	local failed_backups_tmp_file=`mktemp`
	# chuck the failed backups to a temporary file, will be easier to handle
	echo "$failed_backups" > $failed_backups_tmp_file
	for command in `get_commands $backup_model notify`; do
		unset IFS
		local module=`echo $command | cut -d' ' -f1`
		local module_parameters=`echo $command | cut -d' ' -f2-`
		logger_info "Notifying backup status via 'notify::$module' with parameters '$? $module_parameters'"
		# call notify() step
		eval notify _$backup_model $retval $failed_backups_tmp_file $module $module_parameters
	done
	rm -f $failed_backups_tmp_file

	return $retval
}

# prints usage and exits
usage() {
	echo "Usage: $0 [OPTIONS]"
	echo "Runs a backup model"
	echo "
Options:
  -h             Prints this help message.
  -c             Config file to use.
  -m             Model to run. Can be specified multiple time.
"
	exit 2
}

# main
main() {
	local tmp_getops
	tmp_getops=`getopt -o hc:m: --long help,config:,model: -- "$@"`
	[ $? != 0 ] && usage
	eval set -- "$tmp_getops"

	# parse options
	local config models
	while true; do
		case "$1" in
			-h|--help) usage;;
			-c|--config) config="$2"; shift 2;;
			-m|--model) models="$models $2"; shift 2;;
			--) shift; break;;
			*) usage;;
		esac
	done
	[ x"$config" = x ] && usage
	[ x"$models" = x ] && usage

	source $config || logger_fatal "Failed to load config at '$config'"

	local model
	for model in $models; do
		execute_backup $model
	done
}

# main
main2() {
	# create backup destination all the time as the first thing
	# otherwise pull-backups.sh will fail
	test -d $BACKUP_DESTINATION || mkdir -p $BACKUP_DESTINATION

	local backup_destination=`mktemp -d`
	echo "Backup destination is: $backup_destination"
	local backup_module
	local -i retval=0
	if [ x"$BACKUP_MODULES" = x ]; then
		echo "No backup modules defined, quitting" 1>&2
		rmdir $backup_destination
		return 1
	fi
	for backup_module in $BACKUP_MODULES; do
		$backup_module-backup.sh $backup_destination
		let retval=$retval+$?
	done

	# create a temporary filename for backup
	# experimented with bzip2 and gzip is just much faster and compresses
	# almost as much
	local backup_compressed_filename=`mktemp --suffix=-\`hostname\`-\`date '+%Y%m%d-%H%m%S'\`.tar.gz`

	pack_backup $backup_compressed_filename $backup_destination
	let retval=$retval+$?

	spool_backup_to_ftp $backup_compressed_filename
	let retval=$retval+$?

	if [ $retval -eq 0 ]; then
		move_backup_to_backup_directory $backup_compressed_filename && \
		rotate_backups
		let retval=$retval+$?
	fi

	if [ x"$backup_destination" = x -o "$backup_destination" = "/" ]; then
		echo "backup script tried to remove an empty directory, or the root directory - THIS IS A SERIOUS BUG!!!" 1>2
		exit 15
	fi
	rm -rf --preserve-root $backup_destination
	rm -f $backup_compressed_filename

	return $retval
}

main "$@"
