#!/bin/bash
set -e

if cat /etc/redhat-release | grep 'release 7'; then
	cmd="exec command python2 ./_tcpconnect.py"
else
	cmd="exec command python ./_tcpconnect.py"
fi

>&2 echo -e $cmd
eval $cmd
