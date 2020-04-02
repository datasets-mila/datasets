#!/bin/bash

BELUGA=278b9bfe-24da-11e9-9fa2-0a06afd4a22e
BELUGA_ROOT=projects/rpp-bengioy/data/curated

SUPER_DS=/network/datasets
DATASET=covid-19/ecdc_covid-19

cd $SUPER_DS

(nice ionice -n7 ./scripts/sync_dataset.sh --dataset=$DATASET)

export TZ=CET

at 16:30 TOMORROW <<<"$PWD/scripts/schedule_sync_ecdc_covid-19_cc.sh"
