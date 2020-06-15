#!/bin/bash
set -e
IGNORED_EXECS="$(./get_ignored_execs.sh)"
INCLUDED_FILE=/tmp/.dev.included
EXCLUDED_FILE=/tmp/.dev.excluded
INCLUDED_FILTER_CMD="egrep -v \"$IGNORED_EXECS\" > $INCLUDED_FILE"
EXCLUDED_FILTER_CMD="egrep \"$IGNORED_EXECS\" > $EXCLUDED_FILE"

OUTPUT_FILE=~/.execsnoops.txt
cmd="exec ./execsnoop.sh \
    | grep '^{' \
    | tee >($INCLUDED_FILTER_CMD) \
    | tee >($EXCLUDED_FILTER_CMD) \
    | tee $OUTPUT_FILE"

eval $cmd
