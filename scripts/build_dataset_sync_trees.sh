#!/bin/bash

SUPER_DS=/network/datasets

cd $SUPER_DS

source scripts/activate_datalad.sh

SYNC_DS=$PWD/.$(basename $PWD)_sync_tree

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
	>&2 echo --dataset option must be an existing directory
	>&2 echo missing --dataset option
	exit 1
fi

cd $SYNC_DS

(cd $SUPER_DS && [ "$(cat $SYNC_DS/$DATASET/commit_hash)" != "$(git -C $DATASET rev-parse HEAD)" ] && \
	rm -rf $SYNC_DS/$DATASET/* && \
	find -L $DATASET/* -name ".*" -prune -o \
	-name "*.jugdata" -prune -o \
	\( -type d -exec echo dir :"{}" \; -exec mkdir $SYNC_DS/"{}" \; -o \
	   -type f -exec echo file:"{}" \; -exec ln -L $PWD/"{}" $SYNC_DS/"{}" \; \) && \
	echo "$(git -C $DATASET rev-parse HEAD)" > $SYNC_DS/$DATASET/commit_hash )
