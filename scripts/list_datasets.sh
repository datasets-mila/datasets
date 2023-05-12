#!/bin/bash
pushd `dirname "${BASH_SOURCE[0]}"` >/dev/null
cd ..
_DS_DIR=`pwd -P`
popd >/dev/null

_PREPROCESS_DIR=

while [[ $# -gt 0 ]]
do
	_ARG="$1"; shift
	case "${_ARG}" in
		--huggingface | --parlai | --torchvision | --tensorflow)
		_PREPROCESS_DIR=${_ARG/--/}
		;;
		-h | --help)
		>&2 echo "Options for $(basename "$0") are:"
		>&2 echo "--huggingface list only Hugging Face ready datasets variants"
		>&2 echo "--parlai list only ParlAI ready datasets variants"
		>&2 echo "--torchvision list only Torchvision ready datasets variants"
		>&2 echo "--tensorflow list only TensorFlow ready datasets variants"
		exit 1
		;;
		--) break ;;
		*) >&2 echo "Unknown option [${_arg}]"; exit 3 ;;
	esac
done

pushd ${_DS_DIR} >/dev/null
source scripts/activate_datalad.sh
popd >/dev/null

set -o errexit -o pipefail -o noclobber

if [[ ! -z "${_PREPROCESS_DIR}" ]]
then
	ls -l "${_DS_DIR}/${_PREPROCESS_DIR}/" | grep -oE "[^ ]*_${_PREPROCESS_DIR}/" | grep -oE "[^\./].*[^/]" | sort -u
else
	pushd ${_DS_DIR} >/dev/null
	scripts/utils.sh subdatasets --var
	popd >/dev/null
fi
