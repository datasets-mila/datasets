#!/bin/bash

SUPER_DS=/network/datasets

cd $SUPER_DS

source scripts/activate_datalad.sh

datalad install -s . .$(basename $PWD)_sync_tree
(cd .$(basename $PWD)_sync_tree && \
 chmod o-rwx $PWD && \
 datalad update -s origin && \
 git reset --hard origin/master)

subdatasets=$(datalad subdatasets | grep -o ": .* (dataset)" | grep -o " .* " | grep -o "[^ ]*")
for subdataset in ${subdatasets[*]}
do
	(./scripts/build_dataset_sync_trees.sh --dataset=$subdataset)
done
