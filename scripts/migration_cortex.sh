#!/bin/bash

dirnames=(
# 	"172.16.4.191:/network/datasets/./.annex-cache"
# 	"172.16.4.191:/network/datasets/./.data1"
	"172.16.4.191:/network/datasets/./.datalad"
	"172.16.4.191:/network/datasets/./.dataset_template"
# 	"172.16.4.191:/network/datasets/./.datasets_sync_tree"
	"172.16.4.191:/network/datasets/./.git"
	"172.16.4.191:/network/datasets/./.gitattributes"
	"172.16.4.191:/network/datasets/./.gitignore"
	"172.16.4.191:/network/datasets/./.gitmodules"
	"172.16.4.191:/network/datasets/./.groups"
# 	"172.16.4.191:/network/datasets/./.tmp_processing"
	"172.16.4.191:/network/datasets/./LDC"
	"172.16.4.191:/network/datasets/./README"
	"172.16.4.191:/network/datasets/./ami"
	"172.16.4.191:/network/datasets/./ami.var"
	"172.16.4.191:/network/datasets/./cifar10"
	"172.16.4.191:/network/datasets/./cifar10.var"
	"172.16.4.191:/network/datasets/./cifar100"
	"172.16.4.191:/network/datasets/./cifar100.var"
	"172.16.4.191:/network/datasets/./cityscapes"
	"172.16.4.191:/network/datasets/./cityscapes.var"
	"172.16.4.191:/network/datasets/./climatenet"
	"172.16.4.191:/network/datasets/./coco"
	"172.16.4.191:/network/datasets/./coco.var"
	"172.16.4.191:/network/datasets/./commonvoice"
	"172.16.4.191:/network/datasets/./convai2"
	"172.16.4.191:/network/datasets/./convai2.var"
	"172.16.4.191:/network/datasets/./covid-19"
	"172.16.4.191:/network/datasets/./dcase2020.var"
	"172.16.4.191:/network/datasets/./dns-challenge"
	"172.16.4.191:/network/datasets/./dns-challenge.var"
	"172.16.4.191:/network/datasets/./ffhq"
	"172.16.4.191:/network/datasets/./hotels50K"
	"172.16.4.191:/network/datasets/./hotels50K.var"
	"172.16.4.191:/network/datasets/./icentia11k"
	"172.16.4.191:/network/datasets/./imagenet"
	"172.16.4.191:/network/datasets/./imagenet.var"
	"172.16.4.191:/network/datasets/./index.html"
	"172.16.4.191:/network/datasets/./kitti"
	"172.16.4.191:/network/datasets/./librispeech"
	"172.16.4.191:/network/datasets/./librispeech.var"
	"172.16.4.191:/network/datasets/./lincs_l1000"
	"172.16.4.191:/network/datasets/./mimii"
	"172.16.4.191:/network/datasets/./mimii.var"
	"172.16.4.191:/network/datasets/./mnist"
	"172.16.4.191:/network/datasets/./mnist.var"
	"172.16.4.191:/network/datasets/./modelnet40"
	"172.16.4.191:/network/datasets/./naturalquestions"
	"172.16.4.191:/network/datasets/./nwm"
	"172.16.4.191:/network/datasets/./open_images"
	"172.16.4.191:/network/datasets/./parlai"
	"172.16.4.191:/network/datasets/./personachat"
	"172.16.4.191:/network/datasets/./personachat.var"
	"172.16.4.191:/network/datasets/./perturbseq"
	"172.16.4.191:/network/datasets/./playing_for_data"
	"172.16.4.191:/network/datasets/./previous_data1_duplicates"
	"172.16.4.191:/network/datasets/./previous_data1_structure"
	"172.16.4.191:/network/datasets/./restricted"
	"172.16.4.191:/network/datasets/./scripts"
	"172.16.4.191:/network/datasets/./songlyrics"
	"172.16.4.191:/network/datasets/./tensorflow"
	"172.16.4.191:/network/datasets/./timit"
	"172.16.4.191:/network/datasets/./tinyimagenet"
	"172.16.4.191:/network/datasets/./tinyimagenet.var"
	"172.16.4.191:/network/datasets/./torchvision"
	"172.16.4.191:/network/datasets/./toyadmos"
	"172.16.4.191:/network/datasets/./toyadmos.var"
	"172.16.4.191:/network/datasets/./twitter.var"
	"172.16.4.191:/network/datasets/./twitter"
	"172.16.4.191:/network/datasets/./ubuntu"
	"172.16.4.191:/network/datasets/./ubuntu.var"
	"172.16.4.191:/network/datasets/./wikitext"
	)

time rsync --archive \
	--recursive \
	--relative \
	--update \
	--links \
	--hard-links \
	--perms \
	--chmod="o-wx,o+r" \
	--delete-during \
	--chown=:datasets_mgmt \
	--partial \
	--exclude=.nfs* \
	--progress \
	"${dirnames[@]}" \
	/network/datasets/
