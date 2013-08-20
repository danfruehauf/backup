# backup rock

Quick, lean and modular backup system, implemented in Bash.

Inspired by the pretty successful and famous
[backup gem](https://github.com/meskyanichi/backup), but disappointed by the
tremendous amount of dependencies needed to install (250mb!!) I've decided
it's time to create a modular backup system without all the clutter and
overhead that ruby features. I present you the <b>backup rock</b>, in contrast
to a (ruby) gem.

In addition to that - the backup rock also features a <b>restore</b> mode. By
reversing the operations we perform to backup, we can restore things easily
from a backup.

## High Level Design

The backup rock is a simple and linear backup system, it performs a 4 step
backup:
 * log - Not really a step, but defines loggers that will be loaded
 * backup - Actual backup, dumping of DBs, creating archive, etc.
 * process - Encryption, compression
 * store - Store the backup, perhaps in multiple locations
 * notify - Notifies the status of the backup

When performing a restore, the steps are almost reversed:
 * log - Loading loggers
 * store - Find a backup we can restore from
 * process - Decryption, decompression
 * backup - Performs a restore, rather than a backup
 * notify - Same, just notifies

Each of these steps is modular and the user is encouraged to add more plugins
as he/she sees fit.

## Backup Models

In order to perform a backup with the backup rock, you will need to write a
model file. The model file models how backup and restore should be carried out.
A simple model file to backup `/etc/shadow` into `/var/backups` will look like
that:
```
backup() {
	rsync shadow /etc/shadow
}
store() {
	cp /var/backups
}
```

Backup a MySQL and PgSQL database to `/var/backups`:
```
backup() {
	pgsql db_name localhost:5432:db_name:username:password
	mysql db_name localhost:3306:db_name:username:password
}
store() {
	cp /var/backups
}
```

Please have a look at some more examples under [models](models).

## Plugins

 * log
   * [logfile](modules/log/logfile.sh) - Simple log file logging
   * [syslog](modules/log/syslog.sh) - Logging to syslog via '/bin/logger'
 * backup
   * [execute](modules/backup/execute.sh) - Execute any shell command
   * [mysql](modules/backup/mysql.sh) - MySQL database backup
   * [pgsql](modules/backup/pgsql.sh) - PostgreSQL database backup
   * [rsync](modules/backup/rsync.sh) - Pull files using rsync
   * [tar](modules/backup/tar.sh) - Create tar archives
 * process
   * [gpg](modules/process/gpg.sh) - GPG encryption
   * [bzip2](modules/process/bzip2.sh) - bzip2 compression
   * [gzip](modules/process/gzip.sh) - gzip compression
   * [xz](modules/process/xz.sh) - xz compression
   * [split](modules/process/split.sh) - Splitting files into smaller ones
 * store
   * [cp](modules/store/cp.sh) - Store backup locally with cp
   * [scp](modules/store/scp.sh) - Store backup remotely using scp
   * [cycle](modules/store/cycle.sh) - Used to cycle backups
 * notify
   * [email](modules/notify/email.sh) - Notify via email, using mailx
   * [pushover](modules/notify/pushover.sh) - Notify via [pushover](https://pushover.net)
   * [nagios_nsca](modules/notify/nagios_nsca.sh) - Notify via Nagios NSCA

## Usage

Simplicty is key. To backup, run:
```
$ ./backup -m model_file
```

And to restore:
```
$ ./backup -r -m model_file
```

