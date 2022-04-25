#!/bin/bash

SUPER_DS=/network/datasets
DATASET=covid-19/ecdc_covid-19

cd $SUPER_DS

(nice ionice -n7 ./scripts/build_dataset_sync_trees.sh --dataset=$DATASET)
(nice ionice -n7 ./scripts/sync_dataset.sh --dataset=$DATASET)

export TZ=CET

at 16:30 TOMORROW <<<"$PWD/scripts/schedule_sync_ecdc_covid-19_cc.sh"
