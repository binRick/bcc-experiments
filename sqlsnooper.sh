#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
#source setup.sh

if cat /etc/redhat-release | grep 'release 7'; then
	cmd="command sudo -nu root command python2 ./_sqlsnooper.py"
else
	cmd="commnd sudo -nu root /usr/libexec/platform-python ./_sqlsnooper.py"
fi


cmd="exec $cmd $(pgrep -n mysqld) 0"
>&2 echo -e $cmd


eval $cmd
