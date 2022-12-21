#!/bin/bash

SUPER_DS=/network/datasets

pushd "${SUPER_DS}"

source scripts/activate_datalad.sh
source scripts/utils.sh echo -n
set -o errexit -o pipefail

WL_DIR=.$(basename $PWD)_sync_tree/.whitelist/

_cc_clusters=(mila cc-beluga cc-narval cc-cedar)

# Copy scripts/list_datasets_cc.sh to remote clusters
for _cluster in "${_cc_clusters[@]:1}"
do
	_prefix=$(echo "$_cluster" | cut -d'-' -f1 -)
	_cluster=$(echo "$_cluster" | cut -d'-' -f2 -)

	if [[ -z "${_cluster}" ]]
	then
		_cluster=${_prefix}
	fi

	if [[ "${_prefix}" == "cc" ]]
	then
		_config_cluster=computecanada.${_cluster}
	fi

	echo "$_prefix"
	echo "$_cluster"
	echo "$_config_cluster"
	echo "_TO_ROOT=\$(git config -f scripts/config/config --get ${_config_cluster}.data-root)"

	_TO_ROOT=$(git config -f scripts/config/config --get ${_config_cluster}.data-root)

	echo $_TO_ROOT

	# cc-cedar has issues connecting so this might fail here
	scp scripts/list_datasets_cc.sh ${_cluster}:"${_TO_ROOT}/list_datasets_cc.sh"
done

subdatasets --var | while read subds
do
	if ! grep "^1" "${WL_DIR}/${subds}/check" > /dev/null
	then
		continue
	fi

	./scripts/sync_dataset.sh --dataset "${subds}" --from "${_cc_clusters[0]}" --to "${_cc_clusters[1]}"
	for _cluster in "${_cc_clusters[@]:2}"
	do
		./scripts/sync_dataset.sh --dataset "${subds}" --from "${_cc_clusters[1]}" --to "${_cluster}" &
	done

	for _jid in $(jobs -rp)
	do
		wait $_jid
	done
done

popd
