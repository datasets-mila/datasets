#!/bin/bash

export PATH="$(cd ~; pwd)/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

pyenv deactivate
pyenv activate miniconda3-4.3.30/envs/datalad

SUPER_DS=/network/datasets

cd $SUPER_DS

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
