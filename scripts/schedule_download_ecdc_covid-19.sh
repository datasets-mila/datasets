#!/bin/bash

SUPER_DS=/network/datasets
DATASET=covid-19/ecdc_covid-19

cd $SUPER_DS

export TZ=CET

(source scripts/activate_datalad.sh && cd $DATASET && nice ionice -n7 datalad run scripts/download.sh)

at 16:00 TOMORROW <<<"$PWD/scripts/schedule_download_ecdc_covid-19.sh"
