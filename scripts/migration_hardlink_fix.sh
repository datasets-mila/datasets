#!/bin/bash

_err_file=.log/migration_cortex.err
# _cortex=172.16.4.191
_cortex=172.16.4.141

function copy_missing_files {
	local dest
	local src
	local dirnames=()
	while IFS= read -r _file
	do
		dest=`echo "${_file}" | grep -o "\".*\" => "`
		# strip `"/network/datasets/` and `" => `
		dest=${dest:19:-5}
		src=`echo "${_file}" | grep -o " => .*"`
		src=${src:4}
		cp -af "${src}" "${dest}"
		dirnames+=("${_cortex}:/network/datasets/./$(dirname "${src}")")
		dirnames+=("${_cortex}:/network/datasets/./$(dirname "${dest}")")
	done <<< $(cat "${_err_file}" | grep -oE "\".*/${2}.* => .*/${2}[a-z0-9]{2}/[a-z0-9]*")
	IFS=$'\n' dirnames=($(sort -u <<<"${dirnames[*]}"))
	unset IFS
	for d in "${dirnames[@]}"
	do
		time rsync --archive \
			--recursive \
			--relative \
			--update \
			--links \
			--perms \
			--chmod="o-wx,o+r" \
			--delete-during \
			--chown=:datasets_mgmt \
			--partial \
			--exclude=.nfs* \
			--progress \
			"$d" \
			/network/datasets/
	done
}

copy_missing_files "${_err_file}" ".git/objects/"
