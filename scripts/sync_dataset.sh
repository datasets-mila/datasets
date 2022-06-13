#!/bin/bash

SUPER_DS=/network/datasets

pushd "${SUPER_DS}"

source scripts/activate_globus.sh
source scripts/utils.sh echo -n
set -o errexit -o pipefail

MILA=$(git config -f scripts/config/config --get mila.globus)
BELUGA=$(git config -f scripts/config/config --get computecanada.beluga.globus)

MILA_ROOT=$(git config -f scripts/config/config --get mila.data-root)
BELUGA_ROOT=$(git config -f scripts/config/config --get computecanada.beluga.data-root)

SYNC_DS=.$(basename $PWD)_sync_tree

cd $SYNC_DS

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

if [ -z "${_DATASET}" ]
then
	>&2 echo missing --dataset option
	exit 1
fi

cd ${_DATASET}
if [[ "$(cat commit_hash)" != "$(ssh beluga "cat '${BELUGA_ROOT}/$_DATASET/commit_hash'")" ]]
then
	scp beluga:"${BELUGA_ROOT}/$_DATASET/files_list" _files_list_beluga || touch _files_list_beluga
	! diff files_list _files_list_beluga > _files_list_beluga.diff
	grep "<" _files_list_beluga.diff | cut -d':' -f2- - | \
	globus transfer --skip-activation-check \
		--sync-level mtime \
		--preserve-mtime \
		--delete \
		--label "sync ${_DATASET//\// } $(date -u +%C-%m-%d)" \
		--batch - \
		"${MILA}:${SUPER_DS}" "${BELUGA}:${BELUGA_ROOT}/.in" | \
		grep "Task ID:" | cut -d":" -f2- > _beluga_transfer.task
	globus task wait -H $(cat _beluga_transfer.task)

	for f in "commit_hash"
	do
		echo "'${f}' '${f}'"
	done | \
	globus transfer --skip-activation-check \
		--sync-level mtime \
		--preserve-mtime \
		--label "sync ${_DATASET//\// } commit_hash $(date -u +%C-%m-%d)" \
		--batch - \
		"${MILA}:${PWD}" \
		"${BELUGA}:${BELUGA_ROOT}/.in/${_DATASET}"  | \
		grep "Task ID:" | cut -d":" -f2- > _beluga_commit_hash.task
	globus task wait -H $(cat _beluga_commit_hash.task)

	ssh beluga "cd '${BELUGA_ROOT}/.in/' ; find -L '${_DATASET}'/* -type d -exec mkdir -p '../{}' \\; -o -type f -exec mv -T '{}' '../{}' \\;"
fi

popd
