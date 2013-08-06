#!/bin/bash

# tars arguments
# "$@" - arguments for tar, usually it'll be filenames
execute() {
	# simply create a tar archive
	logger_info "Creating tar archive with parameters '$@'"
	tar -cf $_BACKUP_DEST/$_BACKUP_OBJECT_NAME.tar "$@"
}
