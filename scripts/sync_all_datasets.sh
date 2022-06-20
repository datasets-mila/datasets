#!/bin/bash

SUPER_DS=/network/datasets

pushd "${SUPER_DS}"

source scripts/activate_datalad.sh
source scripts/utils.sh echo -n
set -o errexit -o pipefail

_cc_clusters=(mila cc-beluga cc-narval cc-cedar)
subdatasets --var | while read subds
do
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
