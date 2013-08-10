#!/bin/bash

#
# Copyright (C) 2013 Dan Fruehauf <malkodan@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

######################
# CORE FUNCTIONALITY #
######################
# test logging via log::logfile
test_module_log_logfile() {
	# build a tmp model
	local backup_name="$RANDOM"
	local tmp_model=`mktemp`
	local tmp_log_file1=`mktemp -u`
	local tmp_log_file2=`mktemp -u`
	local tmp_log_file3=`mktemp -u`
	cat > $tmp_model <<EOF
log() {
	logfile $tmp_log_file1
	logfile $tmp_log_file2
	logfile $tmp_log_file3
}
EOF
	bash -x $BACKUP_EXEC -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	assertTrue 'log file created and used' "[ -f $tmp_log_file1 ]"
	assertTrue 'log file created and used' "[ -f $tmp_log_file2 ]"
	assertTrue 'log file created and used' "[ -f $tmp_log_file3 ]"
	rm -f $tmp_log_file1 $tmp_log_file2 $tmp_log_file3 $tmp_model
}

###########
# MODULES #
###########

#######
# TAR #
#######
# test backup::tar backup and restore
test_module_backup_tar() {
	# build a tmp model
	local backup_name="$RANDOM"
	local directory_to_backup=`ls -1 $BACKUP_SOURCE | head -1`
	local tmp_model=`mktemp`
	cat > $tmp_model <<EOF
backup() {
	tar $backup_name $BACKUP_SOURCE/$directory_to_backup
}

store() {
	cp $BACKUP_DEST
}
EOF
	$BACKUP_EXEC -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	assertTrue 'tar backup failed' "test -f ${BACKUP_DEST}/*/$backup_name.tar"

	# remove source directory (it'll come back from backup)
	mv $BACKUP_SOURCE/$directory_to_backup $BACKUP_SOURCE/$directory_to_backup.orig

	# restore!
	$BACKUP_EXEC -r -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"
	rm -f $tmp_model

	# take a diff between directories after restore, they should be identical
	local -i diff_lines=`diff -urN $BACKUP_SOURCE/$directory_to_backup.orig $BACKUP_SOURCE/$directory_to_backup | wc -l`

	assertTrue 'restore not identical to backup' "[ $diff_lines -eq 0 ]"
}

#########
# RSYNC #
#########
# test backup::rsync backup
test_module_backup_rsync() {
	# build a tmp model
	local backup_name="$RANDOM"
	local tmp_model=`mktemp`
	cat > $tmp_model <<EOF
backup() {
	rsync $backup_name $BACKUP_SOURCE/backup
}

store() {
	cp $BACKUP_DEST
}
EOF
	$BACKUP_EXEC -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"
	rm -f $tmp_model

	local backup_timestamp=`ls -1 $BACKUP_DEST`
	local -i diff_lines=`diff -urN $BACKUP_SOURCE $BACKUP_DEST/$backup_timestamp/$backup_name | wc -l`

	assertTrue 'rsync not identical to source' "[ $diff_lines -eq 0 ]"
}

#########
# CYCLE #
#########
# test store::cycle backup
test_module_backup_backup_cycle() {
	# build a tmp model
	local -i cycle_backups=2
	local backup_name="$RANDOM"
	local tmp_model=`mktemp`
	cat > $tmp_model <<EOF
backup() {
	rsync $backup_name $BACKUP_SOURCE/backup
}

store() {
	cp $BACKUP_DEST
	cycle $BACKUP_DEST $cycle_backups
}
EOF

	# have at least $cycle_backups in directory
	for i in `seq 1 $cycle_backups`; do
		$BACKUP_EXEC -m $tmp_model >& /dev/null
		assertTrue 'exit status of backup' "[ $? -eq 0 ]"
	done
	local -i backups_nr=`ls -1 $BACKUP_DEST | wc -l`
	assertTrue "cycling broken in directory, have $backups_nr, expected: $cycle_backups" \
		"[ $backups_nr -eq $cycle_backups ]"

	rm -f $tmp_model
}

######
# GZ #
######
# test process::gz backup
test_module_process_gz() {
	# build a tmp model
	local backup_name="$RANDOM"
	local directory_to_backup=`ls -1 $BACKUP_SOURCE | head -1`
	local tmp_model=`mktemp`
	cat > $tmp_model <<EOF
backup() {
	tar $backup_name $BACKUP_SOURCE/$directory_to_backup
}

process() {
	gzip '.*'
}

store() {
	cp $BACKUP_DEST
}
EOF
	$BACKUP_EXEC -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	assertTrue 'tar.gz backup failed' "test -f ${BACKUP_DEST}/*/$backup_name.tar.gz"

	# remove source directory (it'll come back from backup)
	mv $BACKUP_SOURCE/$directory_to_backup $BACKUP_SOURCE/$directory_to_backup.orig

	# restore!
	$BACKUP_EXEC -r -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"
	rm -f $tmp_model

	# take a diff between directories after restore, they should be identical
	local -i diff_lines=`diff -urN $BACKUP_SOURCE/$directory_to_backup.orig $BACKUP_SOURCE/$directory_to_backup | wc -l`

	assertTrue 'restore not identical to backup' "[ $diff_lines -eq 0 ]"
}

#########
# MYSQL #
#########
# test backup::mysql backup
xxxtest_module_backup_mysql() {
	# build a tmp model
	local test_db="test_db_$RANDOM"
	local directory_to_backup=`ls -1 $BACKUP_SOURCE | head -1`
	local tmp_model=`mktemp`
	local test_user=test
	local test_password="${RANDOM}${RANDOM}${RANDOM}"
	cat > $tmp_model <<EOF
backup() {
	mysql $test_db localhost::$test_db:$test_user:$test_password
}

store() {
	cp $BACKUP_DEST
}
EOF
	# before running this section, you'll probably have to execute something
	# like:
	# echo "GRANT ALL PRIVILEGES ON *.* to $USER@'localhost' WITH GRANT OPTION;" | mysql
	# echo "FLUSH PRIVILEGES;" | mysql
	# another option is to change $mysql_executable run with admin credentials
	local mysql_admin_privs='mysql'
	local mysql_backup_privs="mysql -h localhost -u $test_user -p$test_password $test_db"

	# assume we have full local mysql access
	echo "CREATE DATABASE $test_db" | $mysql_admin_privs
	echo "CREATE USER $test_user@'localhost' IDENTIFIED BY '$test_password'" | $mysql_admin_privs
	echo "GRANT ALL ON $test_db.* TO $test_user@'localhost'" | $mysql_admin_privs
	assertTrue 'privileges granting' "[ $? -eq 0 ]"

	# build the database
	echo "CREATE TABLE $test_db.$test_db (c1 INT, c2 INT);" | $mysql_backup_privs
	echo "INSERT INTO $test_db.$test_db (c1, c2) VALUES (1,2)" | $mysql_backup_privs
	echo "INSERT INTO $test_db.$test_db (c1, c2) VALUES (3,4)" | $mysql_backup_privs
	assertTrue 'table creation' "[ $? -eq 0 ]"

	# save the table in a file
	local tmp_output1=`mktemp`
	echo "SELECT * FROM $test_db.$test_db" | $mysql_backup_privs > $tmp_output1

	$BACKUP_EXEC -m $tmp_model #>& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	# backup succeeded?
	assertTrue 'mysql backup failed' "test -f ${BACKUP_DEST}/*/$test_db.sql"

	# remove database and recreate it
	echo "DROP DATABASE $test_db" | $mysql_admin_privs
	echo "GRANT ALL ON $test_db.* TO $test_user@'localhost'" | $mysql_admin_privs
	echo "CREATE DATABASE $test_db" | $mysql_admin_privs
	echo "GRANT ALL ON $test_db.* TO $test_user@'localhost'" | $mysql_admin_privs

	# make sure the database was dropped
	echo "SELECT * FROM $test_db.$test_db" | $mysql_backup_privs >& /dev/null
	assertFalse 'database dropped' "[ $? -eq 0 ]"

	# restore!
	$BACKUP_EXEC -r -m $tmp_model #>& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	# see what came out after the restore
	local tmp_output2=`mktemp`
	echo "SELECT * FROM $test_db.$test_db" | $mysql_admin_privs > $tmp_output2

	# take a diff between directories after restore, they should be identical
	local -i diff_lines=`diff -urN $tmp_output1 $tmp_output2 | wc -l`
	assertTrue 'restore not identical to backup' "[ $diff_lines -eq 0 ]"

	rm -f $tmp_model

	# teardown all the DB stuff
	echo "DROP USER $test_user@'localhost'" | $mysql_admin_privs
	echo "DROP DATABASE $test_db" | $mysql_admin_privs
}

##################
# SETUP/TEARDOWN #
##################

oneTimeSetUp() {
	# load include to test
	BACKUP_EXEC=`dirname $0`/backup.sh
	BACKUP_SOURCE_SETUP=`mktemp -d`
	mkdir -p $BACKUP_SOURCE_SETUP
	# TODO
	#(cd $BACKUP_SOURCE_SETUP && git clone git@github.com:danfruehauf/backup.git)
	(mkdir -p $BACKUP_SOURCE_SETUP/backup && cp -a ./* $BACKUP_SOURCE_SETUP/backup/)
}

oneTimeTearDown() {
	rm -rf --preserve-root $BACKUP_SOURCE_SETUP
}

setUp() {
	BACKUP_DEST=`mktemp -d`
	BACKUP_SOURCE=`mktemp -d`
	cp -a $BACKUP_SOURCE_SETUP/* $BACKUP_SOURCE/
}

tearDown() {
	rm -rf --preserve-root $BACKUP_DEST $BACKUP_SOURCE
}

# load and run shUnit2
. /usr/share/shunit2/shunit2
