#!/bin/bash

MILA=$(git config -f scripts/config/config --get mila.globus)
BELUGA=$(git config -f scripts/config/config --get computecanada.beluga.globus)

MILA_ROOT=$(git config -f scripts/config/config --get mila.data-root)
BELUGA_ROOT=$(git config -f scripts/config/config --get computecanada.beluga.data-root)

SUPER_DS=/network/datasets

cd $SUPER_DS

source scripts/activate_datalad.sh

SYNC_DS=$PWD/.$(basename $PWD)_sync_tree

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
