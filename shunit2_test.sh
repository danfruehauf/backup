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
	$BACKUP_EXEC -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	assertTrue 'log file created and used' "[ -f $tmp_log_file1 ]"
	assertTrue 'log file created and used' "[ -f $tmp_log_file2 ]"
	assertTrue 'log file created and used' "[ -f $tmp_log_file3 ]"
	rm -f $tmp_log_file1 $tmp_log_file2 $tmp_log_file3 $tmp_model
}

# test a bogus model file passed
test_invalid_model() {
	# build a tmp model
	local backup_name="$RANDOM"
	local tmp_model=`mktemp`
	cat > $tmp_model <<EOF
p[INCORRECT BASH SYNTAX((
EOF
	$BACKUP_EXEC -m $tmp_model >& /dev/null
	assertFalse 'exit status of backup' "[ $? -eq 0 ]"

	rm -f $tmp_model
}

###########
# MODULES #
###########

###########
# EXECUTE #
###########
# test backup::execute backup and restore
test_module_backup_execute() {
	# build a tmp model
	local backup_name="$RANDOM"
	local directory_to_backup=`ls -1 $BACKUP_SOURCE | head -1`
	local tmp_model=`mktemp`
	local tmp_file_to_touch=`mktemp -u`
	cat > $tmp_model <<EOF
backup() {
	tar $backup_name $BACKUP_SOURCE/$directory_to_backup
	execute "touch a temporary file" touch $tmp_file_to_touch
}
store() {
	cp $BACKUP_DEST
}
EOF
	$BACKUP_EXEC -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	assertTrue 'execute plugin failed' "test -f $tmp_file_to_touch"

	# remove tmp_file_to_touch before testing restore
	rm -f $tmp_file_to_touch

	# restore!
	$BACKUP_EXEC -r -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	# make sure file exists again
	assertTrue 'execute plugin failed' "test -f $tmp_file_to_touch"

	# cleanup
	rm -f $tmp_model $tmp_file_to_touch
}


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

# test backup::tar backup and exclude
test_module_backup_tar_excludes() {
	# build a tmp model
	local backup_name="$RANDOM"
	local directory_to_backup=`ls -1 $BACKUP_SOURCE | head -1`
	local file_to_exclude=$BACKUP_SOURCE/$directory_to_backup/EXCLUDED
	echo "this file is excluded" > $file_to_exclude
	local tmp_model=`mktemp`
	cat > $tmp_model <<EOF
backup() {
	tar $backup_name $BACKUP_SOURCE/$directory_to_backup --exclude=EXCLUDED
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

	assertFalse 'excluded file found after restore' "[ -f $file_to_exclude ]"
}

# test backup::tar backup and sudo
test_module_backup_tar_sudo() {
	# build a tmp model
	local backup_name="$RANDOM"
	local directory_to_backup=`ls -1 $BACKUP_SOURCE | head -1`
	local tmp_model=`mktemp`
	cat > $tmp_model <<EOF
backup() {
	tar $backup_name --sudo $BACKUP_SOURCE/$directory_to_backup
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
# MYSQL #
#########
# test backup::mysql backup and restore
test_module_backup_mysql() {
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

	$BACKUP_EXEC -m $tmp_model >& /dev/null
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
	$BACKUP_EXEC -r -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	# see what came out after the restore
	local tmp_output2=`mktemp`
	echo "SELECT * FROM $test_db.$test_db" | $mysql_backup_privs > $tmp_output2

	# take a diff between directories after restore, they should be identical
	local -i diff_lines=`diff -urN $tmp_output1 $tmp_output2 | wc -l`
	assertTrue 'restore not identical to backup' "[ $diff_lines -eq 0 ]"

	# teardown all the DB stuff
	echo "DROP USER $test_user@'localhost'" | $mysql_admin_privs
	echo "DROP DATABASE $test_db" | $mysql_admin_privs

	# cleanup
	rm -f $tmp_model $tmp_output1 $tmp_output2
}

#########
# PGSQL #
#########
# test backup::pgsql backup and restore
test_module_backup_pgsql() {
	# build a tmp model
	local test_db="test_db_$RANDOM"
	local directory_to_backup=`ls -1 $BACKUP_SOURCE | head -1`
	local tmp_model=`mktemp`
	local test_user=test
	local test_password="${RANDOM}${RANDOM}${RANDOM}"
	cat > $tmp_model <<EOF
backup() {
	pgsql $test_db localhost::$test_db:$test_user:$test_password
}

store() {
	cp $BACKUP_DEST
}
EOF
	# before running this section, you'll probably have to execute something
	# like:
	# echo "CREATE ROLE $USER WITH SUPERUSER LOGIN PASSWORD 'some_password';" | psql
	# another option is to change $pgsql_executable run with admin credentials like:
	# local pgsql_admin_privs="sudo su - postgres -c 'psql'"
	local pgpass_file_admin=`mktemp`
	chmod 600 $pgpass_file_admin
	echo "localhost:5432:template1:$USER:some_password" > $pgpass_file_admin
	local pgsql_admin_privs='PGPASSFILE=$pgpass_file_admin psql -h localhost -U $USER -d template1'

	local pgpass_file_backup=`mktemp`
	chmod 600 $pgpass_file_backup
	echo "localhost:5432:$test_db:$test_user:$test_password" > $pgpass_file_backup
	local pgsql_backup_privs='PGPASSFILE=$pgpass_file_backup psql -h localhost -U $test_user -d $test_db'

	# create role and database
	echo "DROP ROLE $test_user" | eval $pgsql_admin_privs >& /dev/null
	echo "CREATE ROLE $test_user LOGIN PASSWORD '$test_password'" | eval $pgsql_admin_privs >& /dev/null
	echo "CREATE DATABASE $test_db owner=$test_user" | eval $pgsql_admin_privs >& /dev/null
	assertTrue 'privileges granting' "[ $? -eq 0 ]"

	# build the database
	echo "CREATE TABLE $test_db (c1 INTEGER, c2 INTEGER);" | eval $pgsql_backup_privs >& /dev/null
	echo "INSERT INTO $test_db (c1, c2) VALUES (1,2);" | eval $pgsql_backup_privs >& /dev/null
	echo "INSERT INTO $test_db (c1, c2) VALUES (3,4);" | eval $pgsql_backup_privs >& /dev/null
	assertTrue 'table creation' "[ $? -eq 0 ]"

	# save the table in a file
	local tmp_output1=`mktemp`
	echo "SELECT * FROM $test_db" | eval $pgsql_backup_privs > $tmp_output1

	$BACKUP_EXEC -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	# backup succeeded?
	assertTrue 'pgsql backup failed' "test -f ${BACKUP_DEST}/*/$test_db.sql"

	# remove database and recreate it
	echo "DROP DATABASE $test_db" | eval $pgsql_admin_privs >& /dev/null
	echo "CREATE DATABASE $test_db owner=$test_user" | eval $pgsql_admin_privs >& /dev/null

	# make sure the database was dropped
	local tmp_query_output=`mktemp`
	echo "SELECT * FROM $test_db" | eval $pgsql_backup_privs > $tmp_query_output 2> /dev/null
	assertTrue 'database dropped' "[ `wc -c $tmp_query_output | cut -d' ' -f1` -eq 0 ]"

	# restore!
	$BACKUP_EXEC -r -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	# see what came out after the restore
	local tmp_output2=`mktemp`
	echo "SELECT * FROM $test_db" | eval $pgsql_backup_privs > $tmp_output2

	# take a diff between directories after restore, they should be identical
	local -i diff_lines=`diff -urN $tmp_output1 $tmp_output2 | wc -l`
	assertTrue 'restore not identical to backup' "[ $diff_lines -eq 0 ]"

	# teardown all the DB stuff
	echo "DROP DATABASE $test_db" | eval $pgsql_admin_privs >& /dev/null
	echo "DROP ROLE $test_user" | eval $pgsql_admin_privs >& /dev/null

	rm -f $tmp_model $pgpass_file_admin $pgpass_file_backup \
		$tmp_query_output $tmp_output1 $tmp_output2
}


########
# GZIP #
########
# test process::bzip backup and restore
test_module_process_gzip() {
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
# BZIP2 #
#########
# test process::bzip2 backup and restore
test_module_process_bzip2() {
	# build a tmp model
	local backup_name="$RANDOM"
	local directory_to_backup=`ls -1 $BACKUP_SOURCE | head -1`
	local tmp_model=`mktemp`
	cat > $tmp_model <<EOF
backup() {
	tar $backup_name $BACKUP_SOURCE/$directory_to_backup
}

process() {
	bzip2 '.*'
}

store() {
	cp $BACKUP_DEST
}
EOF
	$BACKUP_EXEC -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	assertTrue 'tar.bz2 backup failed' "test -f ${BACKUP_DEST}/*/$backup_name.tar.bz2"

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

######
# XZ #
######
# test process::xz backup and restore
test_module_process_xz() {
	# build a tmp model
	local backup_name="$RANDOM"
	local directory_to_backup=`ls -1 $BACKUP_SOURCE | head -1`
	local tmp_model=`mktemp`
	cat > $tmp_model <<EOF
backup() {
	tar $backup_name $BACKUP_SOURCE/$directory_to_backup
}

process() {
	xz '.*'
}

store() {
	cp $BACKUP_DEST
}
EOF
	$BACKUP_EXEC -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	assertTrue 'tar.xz backup failed' "test -f ${BACKUP_DEST}/*/$backup_name.tar.xz"

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
# SPLIT #
#########
# test process::split backup and restore
test_module_process_split() {
	# build a tmp model
	# have at least 2 files here as we should test reconstruction of more than
	# one file in the backup directory when performing a restore
	local backup_name1="$RANDOM"
	local backup_name2="$RANDOM"
	local directory_to_backup=`ls -1 $BACKUP_SOURCE | head -1`
	local tmp_model=`mktemp`
	# max size in bytes to split files
	local -i split_max_size=30000
	cat > $tmp_model <<EOF
backup() {
	tar $backup_name1 $BACKUP_SOURCE/$directory_to_backup
	tar $backup_name2 $BACKUP_SOURCE/$directory_to_backup
}

process() {
	split '.*' $split_max_size
}

store() {
	cp $BACKUP_DEST
}
EOF
	$BACKUP_EXEC -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	local -i files_larger_than_max_size=`find ${BACKUP_DEST} -size +${split_max_size}c | wc -l`
	assertTrue "files larger than $split_max_size exist" "[ $files_larger_than_max_size -eq 0 ]"

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

#######
# GPG #
#######
# test process::gpg backup (no restore)
test_module_process_gpg() {
	local gpg_test_key=`mktemp`
	local gpg_test_key_default=gpg_test_key.asc
	if [ -f $gpg_test_key_default ]; then
		cp -a $gpg_test_key_default $gpg_test_key
	else
		# try to export key
		# skip test if key doesn't exist
		gpg --export  --armor > $gpg_test_key
		[ $? -ne 0 ] && echo "Skipping test 'test_module_process_gpg'" && return
	fi

	assertTrue "gpg key not found" "test -f $gpg_test_key"

	# build a tmp model
	local backup_name="$RANDOM"
	local directory_to_backup=`ls -1 $BACKUP_SOURCE | head -1`
	local tmp_model=`mktemp`
	cat > $tmp_model <<EOF
backup() {
	tar $backup_name $BACKUP_SOURCE/$directory_to_backup
}

process() {
	gpg '.*\.tar' $gpg_test_key
}

store() {
	cp $BACKUP_DEST
}
EOF
	$BACKUP_EXEC -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	# encryption succeded?
	assertTrue 'gpg encryption failed' "test -f ${BACKUP_DEST}/*/$backup_name.tar.gpg"

	# make sure all the files are just encrypted data and not tar
	local num_files_that_are_not_data=`find $BACKUP_DEST -type f -exec file {} \; | grep -v ': data$' | wc -l`
	assertTrue 'non encrypted files found' "[ $num_files_that_are_not_data -eq 0 ]"

	# cleanup
	rm -f $tmp_model $gpg_test_key
}


#########
# CYCLE #
#########
# test store::cycle backup
test_module_store_cycle() {
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

	# have at least $cycle_backups+3 in directory
	local -i backups_to_procude=`expr $cycle_backups + 3`
	for i in `seq 1 $backups_to_procude`; do
		$BACKUP_EXEC -m $tmp_model >& /dev/null
		assertTrue 'exit status of backup' "[ $? -eq 0 ]"
	done
	local -i backups_nr=`ls -1 $BACKUP_DEST | wc -l`
	assertTrue "cycling broken in directory, have $backups_nr, expected: $cycle_backups" \
		"[ $backups_nr -eq $cycle_backups ]"

	rm -f $tmp_model
}

############
# S3_CYCLE #
############
# test store::cycle backup
test_module_store_s3_cycle() {
	# build a tmp model
	local -i cycle_backups=2
	local backup_name="$RANDOM"
	local tmp_model=`mktemp`
	cat > $tmp_model <<EOF
backup() {
	tar $backup_name $BACKUP_SOURCE/$directory_to_backup
}
store() {
	s3 $backup_name --access_key=$AWS_ACCESS_KEY --secret_key=$AWS_SECRET_KEY
	s3_cycle $backup_name $cycle_backups --access_key=$AWS_ACCESS_KEY --secret_key=$AWS_SECRET_KEY
}
EOF

	s3cmd --access_key=$AWS_ACCESS_KEY --secret_key=$AWS_SECRET_KEY mb s3://$backup_name >& /dev/null

	# have at least $cycle_backups+3 in directory
	local -i backups_to_procude=`expr $cycle_backups + 3`
	for i in `seq 1 $backups_to_procude`; do
		$BACKUP_EXEC -m $tmp_model >& /dev/null
		assertTrue 'exit status of backup' "[ $? -eq 0 ]"
	done
	local -i backups_nr=`s3cmd --access_key=$AWS_ACCESS_KEY --secret_key=$AWS_SECRET_KEY ls s3://$backup_name | wc -l`

	assertTrue "cycling broken in bucket, have $backups_nr, expected: $cycle_backups" \
		"[ $backups_nr -eq $cycle_backups ]"

	rm -f $tmp_model

	# cleanup s3 bucket
	s3cmd --access_key=$AWS_ACCESS_KEY --secret_key=$AWS_SECRET_KEY --recursive --force del s3://$backup_name >& /dev/null
	s3cmd --access_key=$AWS_ACCESS_KEY --secret_key=$AWS_SECRET_KEY rb s3://$backup_name >& /dev/null
}

######
# S3 #
######
# test store::s3 backup
test_module_store_s3() {
	# build a tmp model
	local backup_name="$RANDOM"
	local directory_to_backup=`ls -1 $BACKUP_SOURCE | head -1`
	local tmp_model=`mktemp`
	cat > $tmp_model <<EOF
backup() {
	tar $backup_name $BACKUP_SOURCE/$directory_to_backup
}
store() {
	s3 $backup_name --access_key=$AWS_ACCESS_KEY --secret_key=$AWS_SECRET_KEY
}
EOF
	s3cmd --access_key=$AWS_ACCESS_KEY --secret_key=$AWS_SECRET_KEY mb s3://$backup_name >& /dev/null

	$BACKUP_EXEC -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	# restore!
	$BACKUP_EXEC -r -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	# cleanup
	rm -f $tmp_model

	# cleanup s3 bucket
	s3cmd --access_key=$AWS_ACCESS_KEY --secret_key=$AWS_SECRET_KEY --recursive --force del s3://$backup_name >& /dev/null
	s3cmd --access_key=$AWS_ACCESS_KEY --secret_key=$AWS_SECRET_KEY rb s3://$backup_name >& /dev/null
}

#################
# NAGIOS_STATUS #
#################
# test notify::nagios_status backup
test_module_notify_nagios_status() {
	# build a tmp model
	local backup_name="$RANDOM"
	local directory_to_backup=`ls -1 $BACKUP_SOURCE | head -1`
	local tmp_model=`mktemp`
	local model_name=`basename $tmp_model`
	local tmp_status_dir=`mktemp -d`
	cat > $tmp_model <<EOF
backup() {
	tar $backup_name $BACKUP_SOURCE/$directory_to_backup
}
notify() {
	nagios_status $tmp_status_dir
}
EOF

	# backup!
	$BACKUP_EXEC -m $tmp_model >& /dev/null
	assertTrue 'exit status of backup' "[ $? -eq 0 ]"

	# compare success message
	local status_message=`cat $tmp_status_dir/$model_name`
	assertTrue 'nagios_status message' \
		"[ '$status_message' = 'OK: Backup successful' ]"

	# create a backup model that'll fail
	cat > $tmp_model <<EOF
backup() {
	tar $backup_name /non-existing-directory
}
notify() {
	nagios_status $tmp_status_dir
}
EOF

	# backup (should fail here!)
	$BACKUP_EXEC -m $tmp_model >& /dev/null
	assertFalse 'exit status of backup' "[ $? -eq 0 ]"

	local status_message=`cat $tmp_status_dir/$model_name`
	assertTrue 'nagios_status message' \
		"[ '$status_message' = 'Critical: Backup failed for: backup::tar' ]"

	# cleanup
	rm -f $tmp_model
	rm -f $tmp_status_dir/$model_name
	rmdir $tmp_status_dir
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

	# AWS settings (for S3)
	source aws-credentials.sh
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
