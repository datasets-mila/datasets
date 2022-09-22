#!/bin/bash

SUPER_DS=/network/datasets

pushd $SUPER_DS

source scripts/activate_datalad.sh
source scripts/utils.sh echo -n
set -o errexit -o pipefail

WL_DIR=.$(basename $PWD)_sync_tree/.whitelist/

subdatasets --var | while read subds
do
	if grep "^1" "${WL_DIR}/${subds}/check" > /dev/null
	then
		./scripts/build_dataset_sync_tree.sh --dataset "${subds}"
	elif [[ -d .$(basename $PWD)_sync_tree/"${subds}" ]]
	then
		echo "Removing ${subds} from sync list"
		rm -r .$(basename $PWD)_sync_tree/"${subds}"
	fi
done

popd
