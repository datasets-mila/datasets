#!/bin/bash

SUPER_DS=/network/datasets

pushd "${SUPER_DS}"

source scripts/activate_datalad.sh
source scripts/utils.sh echo -n
set -o errexit -o pipefail

subdatasets --var | while read subds
do
	./scripts/sync_dataset.sh --dataset "${subds}"
done

popd
