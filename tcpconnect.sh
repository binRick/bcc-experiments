#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
#source setup.sh

if cat /etc/redhat-release | grep 'release 7'; then
	cmd="exec command python2 ./_tcpconnect.py"
else
	cmd="exec command /usr/libexec/platform-python ./_tcpconnect.py"
fi

>&2 echo -e $cmd
eval $cmd
