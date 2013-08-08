#!/bin/bash

# tars arguments
# "$@" - arguments for tar, usually it'll be filenames
backup() {
	# simply create a tar archive
	logger_info "Creating tar archive with parameters '$@'"
	(cd / && tar -cf $_BACKUP_DEST/$_BACKUP_OBJECT_NAME.tar "$@")
}

# untar
# "$@" - arguments for tar, usually it'll be the filename to untar
restore() {
	# restore tar archive
	logger_info "Untarring with parameters '$@'"
	(cd / && tar -xf $_BACKUP_DEST/$_BACKUP_OBJECT_NAME.tar)
}
