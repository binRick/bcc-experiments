#!/bin/bash
set -e
DEFAULT_SCRIPT=execsnoop.sh

if [[ "$1" != "" && -e "$1" ]]; then
    TARGET_SCRIPT="${TARGET_SCRIPT:-$1}"
    shift
else
    TARGET_SCRIPT="${TARGET_SCRIPT:-$DEFAULT_SCRIPT}"
fi

cmd="exec nodemon --delay .1  -w . \
	-w service/*/run \
	 -e sh,j2,py,json,yaml -V -x time -- reap -x ./$TARGET_SCRIPT $@"
[[ "$DEBUG_MODE" == "1" ]] && echo -e $cmd && exit
eval $cmd

