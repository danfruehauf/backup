#!/bin/bash

# logs message via syslog
# "$@" - message to log
initialize() {
	# TODO parse priority/facility
	local log_level=$1; shift
	local log_facility=$1; shift
	/bin/logger -p $log_facility.$log_level "$@"
}
