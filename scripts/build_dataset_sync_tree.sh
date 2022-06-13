#!/bin/bash

SUPER_DS=/network/datasets

pushd "${SUPER_DS}"

source scripts/activate_datalad.sh
source scripts/utils.sh echo -n
set -o errexit -o pipefail

SYNC_DS=.$(basename $PWD)_sync_tree

while [[ $# -gt 0 ]]
do
	_arg=$1; shift
	case "${_arg}" in
		--dataset) _DATASET=$1; shift
		echo "dataset = [${_DATASET}]"
		if [ ! -d "${_DATASET}" ]
		then
			>&2 echo --dataset option must be an existing directory
			unset _DATASET
		fi
		;;
		*)
		>&2 echo Unknown option [${i}]
		exit 1
		;;
	esac
done

if [[ -z "${_DATASET}" ]]
then
	>&2 echo --dataset option must be an existing directory
	>&2 echo missing --dataset option
	exit 1
fi

if [[ "$(cat "${SYNC_DS}/${_DATASET}/commit_hash")" != "$(git -C "${_DATASET}" rev-parse HEAD)" ]]
then
	rm -rf "${SYNC_DS}/${_DATASET}"
	mkdir -p "${SYNC_DS}/${_DATASET}"
	# # Combined with the `--delete' flag, `--recursive' will delete
	# # extraneous files in the destination directory
	# echo "--recursive ${_DATASET} ${_DATASET}" > "${SYNC_DS}/${_DATASET}/files_list"
	find -L "${_DATASET}"/* \( -name ".*" -o -name "*.jugdata" -o -name "bin" \) -prune -o \
		-type f -printf "%C@:%p %p\n" >> "${SYNC_DS}/${_DATASET}/files_list"
	echo ":${SYNC_DS}/${_DATASET}/files_list ${_DATASET}/files_list" >> "${SYNC_DS}/${_DATASET}/files_list"
	echo "$(git -C "${_DATASET}" rev-parse HEAD)" > "${SYNC_DS}/${_DATASET}/commit_hash"
fi

popd
