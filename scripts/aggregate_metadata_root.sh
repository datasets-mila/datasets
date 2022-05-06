#!/bin/bash

source scripts/utils.sh echo -n

set -o errexit -o pipefail

CURR_DIR=${PWD}
META_DIR=.git/datalad/metadata

mkdir -p .tmp_processing
chmod o-rwx .tmp_processing

mkdir -p "${META_DIR}"

datalad install -s . ".tmp_processing/$(basename $PWD)_meta_root"

pushd ".tmp_processing/$(basename $PWD)_meta_root"

mkdir -p "${META_DIR}"
cp -at "${META_DIR}" "${CURR_DIR}/${META_DIR}"/*

subdatasets=$(datalad subdatasets | grep -o ": .* (dataset)" | grep -o " .* " | grep -o "[^ ]*")
for subds in ${subdatasets[*]}
do
	if [ -d "${CURR_DIR}/${subds}/${META_DIR}" ]
	then
		echo "${subds}/${META_DIR}"
		mkdir -p "${subds}/${META_DIR}"
		cp -at "${subds}/${META_DIR}/.." "${CURR_DIR}/${subds}/${META_DIR}"
	fi
	if [ -d "${CURR_DIR}/${subds}.var/" ]
	then
		for subds_var_meta in $(ls -d "${CURR_DIR}/${subds}.var"/*/"${META_DIR}")
		do
			subds_var_meta=$(realpath --relative-to "${CURR_DIR}" "${subds_var_meta}")
			echo "${subds_var_meta}"
			mkdir -p "${subds_var_meta}"
			cp -at "${subds_var_meta}/.." "${CURR_DIR}/${subds_var_meta}"
		done
	fi
done

git-annex get --fast --from origin
GIT_DIR="${PWD}/.git" datalad ls -aL --json file .

cp -at "${CURR_DIR}/${META_DIR}" "${META_DIR}"/*

git-annex drop --fast

popd

rm -rf ".tmp_processing/$(basename $PWD)_meta_root"
