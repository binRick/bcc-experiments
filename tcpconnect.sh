#!/bin/bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source setup_path.sh
source setup_python.sh >/dev/null

if cat /etc/redhat-release | grep -q  'release 7'; then
	cmd="command reap -x python2 ./_tcpconnect.py"
else
	cmd="command reap -x /usr/libexec/platform-python ./_tcpconnect.py"
fi

cmd="command sudo PATH=\"$PATH\" $cmd"
#>&2 echo -e $cmd
eval $cmd
