#!/bin/bash

function _trim_cluster_prefix {
	local _prefix=$(echo "$1" | cut -d'-' -f1 -)
	local _cluster=$(echo "$1" | cut -d'-' -f2 -)

	if [[ -z "${_cluster}" ]]
	then
		local _cluster=${_prefix}
	fi

	echo $_cluster
}

function _get_config_value {
	local _prefix=$(echo "$1" | cut -d'-' -f1 -)
	local _cluster=$(echo "$1" | cut -d'-' -f2 -)
	local _key=$2

	if [[ -z "${_cluster}" ]]
	then
		local _cluster=${_prefix}
	fi

	if [[ "${_prefix}" == "cc" ]]
	then
		local _cluster=computecanada.${_cluster}
	fi

	git config -f scripts/config/config --get ${_cluster}.${_key}
}

function _get_from_commit_hash {
	local _cluster=$1
	if [[ "${_cluster}" == "mila" ]]
	then
		cat commit_hash
	else
		ssh ${_cluster} "cat '${_FROM_ROOT}/$_DATASET/commit_hash'" </dev/null
	fi
}

function _get_to_commit_hash {
	local _cluster=$1
	if [[ "${_cluster}" == "mila" ]]
	then
		cat commit_hash
	else
		ssh ${_cluster} "cat '${_TO_ROOT}/$_DATASET/commit_hash'" </dev/null
	fi
}

function _copy_from_files_list {
	local _cluster=$1
	local _file=$2
	if [[ "${_cluster}" == "mila" ]]
	then
		cp files_list "${_file}" || touch "${_file}"
	else
		scp ${_cluster}:"${_FROM_ROOT}/$_DATASET/files_list" "${_file}" || touch "${_file}"
	fi
}

function _copy_to_files_list {
	local _cluster=$1
	local _file=$2
	if [[ "${_cluster}" == "mila" ]]
	then
		cp files_list "${_file}" || touch "${_file}"
	else
		scp ${_cluster}:"${_TO_ROOT}/$_DATASET/files_list" "${_file}" || touch "${_file}"
	fi
}

function _transfer_meta_file {
	local _cluster=$1
	local _file=$2
	if [[ "${_cluster}" == "mila" ]]
	then
		local _FROM_ROOT=${_FROM_ROOT}/${SYNC_DS}
	fi
	echo "'$_file' '$_file'" | \
	globus transfer --skip-activation-check \
		--sync-level mtime \
		--preserve-mtime \
		--label "sync ${_DATASET//[\/\.]/ } $_file $(date -u +%y-%m-%d)" \
		--batch - \
		"${_FROM_ID}:${_FROM_ROOT}/${_DATASET}" \
		"${_TO_ID}:${_TO_ROOT}/.in/${_DATASET}"
}

SUPER_DS=/network/datasets

pushd "${SUPER_DS}"

source scripts/activate_globus.sh
source scripts/utils.sh echo -n
set -o errexit -o pipefail

SYNC_DS=.$(basename $PWD)_sync_tree
_FROM=mila
_TO=cc-beluga

pushd $SYNC_DS

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
		--from) _FROM=$1; shift
		echo "from = [${_FROM}]"
		;;
		--to) _TO=$1; shift
		echo "to = [${_TO}]"
		;;
		*)
		>&2 echo Unknown option [${i}]
		exit 1
		;;
	esac
done

if [ -z "${_DATASET}" ]
then
	>&2 echo missing --dataset option
	exit 1
fi

popd

_FROM_ID=$(_get_config_value "${_FROM}" globus)
_TO_ID=$(_get_config_value "${_TO}" globus)

_FROM_ROOT=$(_get_config_value "${_FROM}" data-root)
_TO_ROOT=$(_get_config_value "${_TO}" data-root)

pushd $SYNC_DS

_FROM=$(_trim_cluster_prefix "${_FROM}")
_TO=$(_trim_cluster_prefix "${_TO}")
_TASK_NAME=_${_FROM}_${_TO}

cd ${_DATASET}
if [[ "$(_get_from_commit_hash "${_FROM}")" != "$(_get_to_commit_hash "${_TO}")" ]]
then
	_copy_from_files_list "${_FROM}" "${_TASK_NAME}.from_files_list"
	_copy_to_files_list "${_TO}" "${_TASK_NAME}.to_files_list"
	! diff "${_TASK_NAME}.from_files_list" "${_TASK_NAME}.to_files_list" > "${_TASK_NAME}._files_list.diff"
	grep "<" "${_TASK_NAME}._files_list.diff" | cut -d':' -f2- - | \
	globus transfer --skip-activation-check \
		--sync-level mtime \
		--preserve-mtime \
		--delete \
		--label "sync ${_DATASET//[\/\.]/ }${_TASK_NAME} $(date -u +%y-%m-%d)" \
		--batch - \
		"${_FROM_ID}:${_FROM_ROOT}" "${_TO_ID}:${_TO_ROOT}/.in" | \
		grep "Task ID:" | cut -d":" -f2- > ${_TASK_NAME}.transfer.task
	globus task wait -H $(cat ${_TASK_NAME}.transfer.task)

	_transfer_meta_file "${_FROM}" "files_list" | \
		grep "Task ID:" | cut -d":" -f2- | \
		xargs globus task wait -H

	_transfer_meta_file "${_FROM}" "commit_hash" | \
		grep "Task ID:" | cut -d":" -f2- | \
		xargs globus task wait -H

	ssh "${_TO}" "cd '${_TO_ROOT}/.in/' ; find -L '${_DATASET}'/ -type d -exec mkdir -p '../{}' \\; -o -type f -exec mv -T '{}' '../{}' \\;" </dev/null
fi

popd
