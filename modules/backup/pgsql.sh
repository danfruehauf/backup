#!/bin/bash

# Written by Dan Fruehauf <malkodan@gmail.com>

# backup for a pgsql database
# $1 - credentials and settings for pg_dump, a colon separated tuple
# "$@" - parameters for pg_dump
backup() {
	# credentials will be in the form of:
	# HOSTNAME:PORT:DB:USERNAME:PASSWORD
	local credentials=$1; shift
	local host=`echo $credentials | cut -d: -f1`
	local port=`echo $credentials | cut -d: -f2`
	local name=`echo $credentials | cut -d: -f3`
	local user=`echo $credentials | cut -d: -f4`
	local pass=`echo $credentials | cut -d: -f5-`
	logger_info "PgSQL backup initiated with credentials: '$credentials', extra parameters: '$@'"

	local -i retval
	# pass password via PGPASSFILE
	local tmp_pgpass=`mktemp`
	echo "$credentials" > $tmp_pgpass
	PGPASSFILE=$tmp_pgpass pg_dump -O -x -h $host -p $port -U $user $name "$@" > "$_BACKUP_DEST/$_BACKUP_OBJECT_NAME".sql
	retval=$?
	rm -f $tmp_pgpass

	return $retval
}

# restore a pgsql database
# $1 - credentials and settings for psql, a colon separated tuple
# "$@" - parameters for pg_restore
restore() {
	# credentials will be in the form of:
	# HOSTNAME:PORT:DB:USERNAME:PASSWORD
	local credentials=$1; shift
	local host=`echo $credentials | cut -d: -f1`
	local port=`echo $credentials | cut -d: -f2`
	local name=`echo $credentials | cut -d: -f3`
	local user=`echo $credentials | cut -d: -f4`
	local pass=`echo $credentials | cut -d: -f5-`
	logger_info "PgSQL restore initiated with credentials: '$credentials', extra parameters: '$@'"

	local -i retval
	# pass password via PGPASSFILE
	local tmp_pgpass=`mktemp`
	echo "$credentials" > $tmp_pgpass
	PGPASSFILE=$tmp_pgpass psql -h $host -p $port -U $user $name "$@" < "$_BACKUP_DEST/$_BACKUP_OBJECT_NAME".sql
	retval=$?
	rm -f $tmp_pgpass

	return $retval
}

