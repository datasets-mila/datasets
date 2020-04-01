#!/bin/bash

export PATH="$(cd ~; pwd)/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

pyenv deactivate
pyenv activate miniconda3-4.3.30/envs/datalad

MILA=4c35a8e6-685e-11ea-af52-0201714f6eab
BELUGA=278b9bfe-24da-11e9-9fa2-0a06afd4a22e

MILA_ROOT=datasets
BELUGA_ROOT=projects/rpp-bengioy/data/curated

SUPER_DS=/network/datasets
SYNC_DS=$SUPER_DS/.tmp_processing/$(basename $PWD)_sync_tree

cd $SYNC_DS

for i in "$@"
do
	case ${i} in
		--dataset=*)
		DATASET="${i#*=}"
		echo "DATASET = [${DATASET}]"
		if [ ! -d $DATASET ]
		then
			>&2 echo --dataset option must be an existing directory
			unset DATASET
		fi
		;;
		*)
		>&2 echo Unknown option [${i}]
		exit 1
		;;
	esac
done

if [ -z "$DATASET" ]
then
	>&2 echo missing --dataset option
	exit 1
fi

(cd $DATASET && [ "$(cat commit_hash)" != "$(ssh beluga "cat $BELUGA_ROOT/$DATASET/commit_hash")" ] && \
	globus transfer --skip-activation-check \
	--sync-level mtime \
	--preserve-mtime \
	--recursive \
	--delete \
	--label "sync ${DATASET//\// } $(date -u +%C-%m-%d)" \
	$MILA:$MILA_ROOT/$DATASET $BELUGA:$BELUGA_ROOT/$DATASET)
