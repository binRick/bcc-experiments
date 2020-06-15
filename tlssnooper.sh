#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source setup_path.sh

if cat /etc/redhat-release | grep 'release 7'; then
	cmd="command python2 ./_tlssnooper.py"
else
	cmd="command /usr/libexec/platform-python ./_tlssnooper.py"
fi
cmd="exec sudo $cmd"
>&2 echo -e $cmd
eval $cmd
