#!/bin/bash
set -e
MV_VARS="-x 5000 -e"
command -v multiview || npm i multiview -g



TEST_SCRIPTS="$(cd test_scripts && ls tests_*.sh)"


cmd="exec command multiview"
for t in $TEST_SCRIPTS; do
    cmd="$cmd [ ./$t ] "
done
cmd="$cmd $MV_ARGS"

[[ "$DEBUG_MODE" == "1" ]] && echo -e $cmd && exit

cd test_scripts
eval $cmd
