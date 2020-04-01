#!/bin/bash

export PATH="$(cd ~; pwd)/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

pyenv deactivate
pyenv activate miniconda3-4.3.30/envs/datalad

SUPER_DS=/network/datasets

cd $SUPER_DS

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

cd .tmp_processing/$(basename $PWD)_sync_tree

SYNC_DS=$PWD

(cd $SUPER_DS && [ "$(cat $SYNC_DS/$DATASET/commit_hash)" != "$(git -C $DATASET rev-parse HEAD)" ] && \
	rm -rf $SYNC_DS/$DATASET/* && \
	find -L $DATASET/* -name ".*" -prune -o \
	-name "*.jugdata" -prune -o \
	\( -type d -exec echo dir :"{}" \; -exec mkdir $SYNC_DS/"{}" \; -o \
	   -type f -exec echo file:"{}" \; -exec ln -L $PWD/"{}" $SYNC_DS/"{}" \; \) && \
	echo "$(git -C $DATASET rev-parse HEAD)" > $SYNC_DS/$DATASET/commit_hash )
