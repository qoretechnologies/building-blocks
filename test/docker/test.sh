#!/bin/bash

set +e
set -x

for test in `find test -name \*.qtest`; do
    date
    $test -vv
    RESULTS="$RESULTS $?"
    date
done

# check the results
for R in $RESULTS; do
    if [ "$R" != "0" ]; then
        exit 1 # fail
    fi
done
