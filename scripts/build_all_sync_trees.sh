#!/bin/bash

export PATH="$(cd ~; pwd)/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

pyenv deactivate
pyenv activate miniconda3-4.3.30/envs/datalad

SUPER_DS=/network/datasets

cd $SUPER_DS

mkdir -p .tmp_processing
chmod o-rwx .tmp_processing

datalad install -s . .tmp_processing/$(basename $PWD)_sync_tree

subdatasets=$(datalad subdatasets | grep -o ": .* (dataset)" | grep -o " .* " | grep -o "[^ ]*")
for subdataset in ${subdatasets[*]}
do
	(./scripts/build_dataset_sync_trees.sh --dataset=$subdataset)
done
