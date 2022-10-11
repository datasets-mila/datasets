#!/bin/bash

SUPER_DS=/network/datasets

cd $SUPER_DS

source scripts/activate_datalad.sh
source scripts/utils.sh echo -n
set -o errexit -o pipefail

mkdir -p ".$(basename $PWD)_sync_tree/.whitelist"

# Average size / file should be of ~200MB
AVG_SIZE=$((200 * 10**6))
FILES_CNT_THRESHOLD=100

subdatasets --var | while read subds
do
	WL_DS=.$(basename $PWD)_sync_tree/.whitelist/${subds}
	mkdir -p "${WL_DS}"
	if [[ "$(cat "${WL_DS}/commit_hash")" != "$(git -C "${subds}" rev-parse HEAD)" ]]
	then
		find -L ${subds} \( -name ".*" -o -name "*.jugdata" -o -name "bin" -o -name "wget_dir" \) -prune \
			-o -type f -print0 \
			| du -bclD --files0-from - \
			> "${WL_DS}/du"
		echo "$(git -C "${subds}" rev-parse HEAD)" > "${WL_DS}/commit_hash"
	fi

	files_cnt=$(wc -l "${WL_DS}/du" | cut -d" " -f1 || echo 0)
	files_cnt=$((files_cnt - 1))
	size=$(tail -1 "${WL_DS}/du" | cut -f1 || echo 0)

	if [[ $files_cnt -eq 0 ]] || [[ $size -eq 0 ]]
	then
		continue
	fi

	ratio=$((size / files_cnt))

	if [[ $files_cnt -le $FILES_CNT_THRESHOLD ]] || [[ $ratio -ge $AVG_SIZE ]]
	then
		echo -e "1\t$ratio\t$size\t$files_cnt"
	else
		echo -e "0\t$ratio\t$size\t$files_cnt"
	fi > "${WL_DS}/check"
done
