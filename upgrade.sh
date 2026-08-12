#!/bin/bash
set -uo pipefail

./prepare_pkhex_source.sh
prep_exit=$?

if [ $prep_exit -eq 1 ]; then
    exit 0
elif [ $prep_exit -ne 0 ]; then
    echo "Preparation failed... ✗"
    exit 1
fi

./build.sh

echo "Upgrade complete... ✓"
