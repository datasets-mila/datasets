#!/bin/bash

export PATH="$(cd ~; pwd)/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

pyenv deactivate
pyenv activate miniconda3-4.3.30/envs/datalad

SUPER_DS=/network/datasets

cd $SUPER_DS

subdatasets=$(datalad subdatasets | grep -o ": .* (dataset)" | grep -o " .* " | grep -o "[^ ]*")

for subds in ${subdatasets[*]}
do
	(./scripts/sync_dataset.sh --dataset=$subds)
done
