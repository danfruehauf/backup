#!/bin/bash

# logs message to a file
# message will arrive via STDIN
execute() {
	local log_level=$1; shift
	local log_file=$1; shift
	# TODO use $log_level
	cat >> $log_file
}
