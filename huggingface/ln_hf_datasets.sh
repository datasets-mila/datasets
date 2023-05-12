#!/bin/bash

pushd `dirname "${BASH_SOURCE[0]}"` >/dev/null
_SCRIPT_DIR=`pwd -P`
popd >/dev/null

function acquire_lock {
	if [ -e .tmp/lock_hf_ref ]
	then
		[[ "$$" -eq "`cat .tmp/lock_hf_ref`" ]] || return 1
	else
		mkdir -p .tmp/
		echo -n "$$" > .tmp/lock_hf_ref
		chmod -wx .tmp/lock_hf_ref
		[[ "$$" -eq "`cat .tmp/lock_hf_ref`" ]] || return 1
	fi
}

function delete_lock {
	rm -f .tmp/lock_hf_ref
}

function ln_files {
	local _src=$1
	local _dest=$2
	local _workers=$3
	
	(cd "${_src}" && find -L * -type f) | while read f
	do
		[[ "$f" == *.lock ]] && continue
		mkdir --parents "${_dest}/$(dirname "$f")"
		# echo source first so it is matched to the ln's '-T' argument
		readlink --canonicalize "${_src}/$f"
		# echo output last so ln understands it's the output file
		echo "${_dest}/$f"
	done | xargs -n2 -P${_workers} ln -sf -T
}

[[ ! -z "$_SCRIPT_DIR" ]] || exit 1

pushd "${_SCRIPT_DIR}" >/dev/null || exit 1

acquire_lock || exit 1

trap delete_lock EXIT

for ds in ../*.var/*_huggingface
do
	# Clone the dataset structure
	ln_files "${ds}/hf_home" . 1
	ln -sf -T "${ds}"/scripts/preprocess_huggingface.py \
		"$(basename "${ds}")_preprocess.py" 
done

# Remove broken links
find */ -type l | while read f
do
	[[ ! -e "$f" ]] && rm -v "$f"
done

# Remove empty directories
find */ -type d -empty -delete

popd >/dev/null
