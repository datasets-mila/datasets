#!/bin/bash

META_DIR=.git/datalad/metadata

mkdir -p .tmp_processing
chmod o-rwx .tmp_processing

mkdir -p $META_DIR

datalad install -s . .tmp_processing/$(basename $PWD)_meta_root
cd .tmp_processing/$(basename $PWD)_meta_root
git config annex.thin true
git config annex.hardlink true

mkdir -p $META_DIR
cp -at $META_DIR ../../$META_DIR/*

subdatasets=$(datalad subdatasets | grep -o ": .* (dataset)" | grep -o " .* " | grep -o "[^ ]*")
for subdataset in ${subdatasets[*]}
do
	mkdir -p ${subdataset}/$META_DIR
	ln -t ${subdataset}/$META_DIR ../../${subdataset}/$META_DIR/*
	if [ -d ../../${subdataset}.var/ ]
	then
		for subdataset_var in $(ls ../../${subdataset}.var/)
		do
			mkdir -p ${subdataset}.var/$subdataset_var/$META_DIR
			ln -t ${subdataset}.var/$subdataset_var/$META_DIR ../../${subdataset}.var/$subdataset_var/$META_DIR/*
		done
	fi
done

git-annex get --fast --from origin
GIT_DIR="$PWD/.git" datalad ls -aL --json file .

cp -at ../../$META_DIR $META_DIR/*

git-annex drop --fast

cd ../..

rm -rf .tmp_processing/$(basename $PWD)_meta_root
