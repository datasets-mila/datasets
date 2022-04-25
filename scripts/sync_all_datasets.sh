#!/bin/bash

SUPER_DS=/network/datasets

cd $SUPER_DS

source scripts/activate_datalad.sh

subdatasets=$(datalad subdatasets | grep -o ": .* (dataset)" | grep -o " .* " | grep -o "[^ ]*")

for subds in ${subdatasets[*]}
do
	(./scripts/sync_dataset.sh --dataset=$subds)
done
