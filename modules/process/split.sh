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

# suffix for splitting
declare -r SPLIT_SUFFIX=split

# split files in directory
# $1 - regexp for files to split
# $2 - max size of files to split (bytes)
backup() {
	local regexp="$1"; shift
	local -i max_size=$1; shift
	# operate on all files in backup directory that match the given regexp
	find $_BACKUP_DEST -type f -regex "$regexp" -exec sh -c "split -a 3 -b $max_size -d {} {}.$SPLIT_SUFFIX. && rm {}" \;
}

# combine files in directory
# a bit of a harder problem as now we have a many-to-one type of relationship
# $1 - regexp for files to split
# $2 - max size of files to split (bytes)
restore() {
	local regexp="$1"; shift
	local -i max_size=$1; shift

	# operate on all files in backup directory that match the given regexp
	local tmp_files_to_reconstruct=`mktemp`
	_probe_for_splitted_files "$regexp" $tmp_files_to_reconstruct

	local file fragment
	# iterate on all files to be constructed
	while read file; do
		logger_info "Reconstructing '$file'"
		# iterate on all fragments per file
		while read fragment; do
			logger_info "Reconstructing '$fragment' >> '$file'"
			cat "$fragment" >> "$file" && \
				rm -f "$fragment"
		done < <(find $_BACKUP_DEST -type f -regex "$file\.$SPLIT_SUFFIX\.[0-9][0-9][0-9]" | sort)
	done < $tmp_files_to_reconstruct

	# cleanup
	rm -f $tmp_files_to_reconstruct
}

# probe for all files that have been splitted, so we can restructure them
# returns a list of files that should be restructured in $results_file
# $1 - regexp for files to search
# $2 - results file
_probe_for_splitted_files() {
	local regexp="$1"; shift
	local results_file=$1; shift
	# looking for 3 digits as backup ran with 'split -a 3'
	# split the suffix and we have the originial file that was backed up
	find $_BACKUP_DEST -type f -regex "$regexp\.$SPLIT_SUFFIX\.[0-9][0-9][0-9]" | \
		sed -e "s/\.$SPLIT_SUFFIX\.[0-9][0-9][0-9]//g" | sort | uniq > $results_file
}
