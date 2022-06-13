#!/bin/bash
source scripts/datalad.sh --version
set -o errexit -o pipefail
which globus || python3 -m pip install globus-cli
