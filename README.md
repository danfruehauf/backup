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

Please have a look at some more examples under [models](models).

## Plugins

 * log
   * [logfile](modules/log/logfile.sh) - Simple log file logging
   * [syslog](modules/log/syslog.sh) - Logging to syslog via '/bin/logger'
 * backup
   * [mysql](modules/backup/mysql.sh) - MySQL database backup
   * [pgsql](modules/backup/pgsql.sh) - PostgreSQL database backup
   * [rsync](modules/backup/rsync.sh) - Pull files using rsync
   * [tar](modules/backup/tar.sh) - Create tar archives
 * process
   * [gpg](modules/process/gpg.sh) - GPG encryption
   * [gzip](modules/process/gzip.sh) - gzip compression
 * store
   * [cp](modules/store/cp.sh) - Store backup locally with cp
   * [scp](modules/store/scp.sh) - Store backup remotely using scp
   * [cycle](modules/store/cycle.sh) - Used to cycle backups
 * notify
   * [pushover](modules/notify/pushover.sh) - Notify via [pushover](https://pushover.net)
   * [nagios_nsca](modules/notify/nagios_nsca.sh) - Notify via Nagios NSCA

## Usage

Simplicty is key. To backup, run:
```
$ ./backup -c config -m model_file
```

And to restore:
```
$ ./backup -r -c config -m model_file
```

