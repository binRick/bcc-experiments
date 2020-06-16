#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
IGNORED_EXECS="$(./get_ignored_execs.sh)"
IGNORED_BIN_EXECS="$(./get_ignored_formatted_execs.sh)"
#IGNORED_EXECS="$IGNORED_EXECS|$IGNORED_BIN_EXECS"
INCLUDED_FILE=~/.execsnoop.included
EXCLUDED_FILE=~/.execsnoop.excluded
EVERYTHING_FILE=~/.execsnoop.everything
include_json_objects="grep '^{'"
INCLUDED_FILTER_CMD="egrep  -v \"$IGNORED_EXECS\" | $include_json_objects > $INCLUDED_FILE"
EXCLUDED_FILTER_CMD="egrep  \"$IGNORED_EXECS\" | $include_json_objects > $EXCLUDED_FILE"
EVERYTHING_FILTER_CMD="cat > $EVERYTHING_FILE"
uid=$(id -u)
OUTPUT_FILE=~/.execsnoops.txt
cmd="exec ./execsnoop.sh \
    | grep $uid \
    | grep '^{' \
    | tee >($INCLUDED_FILTER_CMD) \
    | tee >($EXCLUDED_FILTER_CMD) \
    | tee >($EVERYTHING_FILTER_CMD) \
    >/dev/null"

eval $cmd
