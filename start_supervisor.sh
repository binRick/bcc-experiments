#!/usr/bin/env bash
set -e
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ctrlc_count=0
source utils.sh
trap no_ctrlc SIGINT
trap kill_my_pids EXIT

BCC_EXPERIMENTS_PROCESS=1 \
    PATH=$PATH:$(pwd)/bin \
    reap -x \
    ./bin/svscan service/.
