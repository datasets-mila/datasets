#!/bin/bash

export PATH="$(cd ~; pwd)/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

pyenv deactivate
pyenv activate miniconda3-4.3.30/envs/datalad

SUPER_DS=/network/datasets
DATASET=covid-19/ecdc_covid-19

cd $SUPER_DS

export TZ=CET

(cd $DATASET && nice ionice -n7 datalad run scripts/download.sh)
(nice ionice -n7 ./scripts/build_dataset_sync_trees.sh --dataset=$DATASET)

at 16:00 TOMORROW <<<"$PWD/scripts/schedule_download_ecdc_covid-19.sh"
