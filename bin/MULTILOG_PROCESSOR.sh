#!/usr/bin/env bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
LF=/tmp/.ml_dev.log

tf=$(mktemp)
cat > $tf
ls -al $tf
date  >> $LF
m="read $(cat $tf|wc -l) lines"
echo -e "$m"  >> $LF
echo -e $m



#unlink $tf

#exit 0
