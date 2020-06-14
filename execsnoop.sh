#!/bin/bash
set -e

if cat /etc/redhat-release | grep 'release 7'; then
	cmd="exec command python2 ./_execsnoop.py"
else
	cmd="exec command /usr/libexec/platform-python ./_execsnoop.py"
fi

>&2 echo -e $cmd
eval $cmd
