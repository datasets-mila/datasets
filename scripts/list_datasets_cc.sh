#!/bin/bash
set -o errexit -o pipefail -o noclobber
pushd `dirname "${BASH_SOURCE[0]}"` >/dev/null
find ./ -name "commit_hash" -exec dirname {} \+ | cut -d'/' -f2- | sort
popd >/dev/null
