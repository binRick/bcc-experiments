#!/usr/bin/env bash
set -e

BCC_EXPERIMENTS_PROCESS=1 \
    PATH=$PATH:$(pwd)/bin \
    reap -x \
    ./bin/svscan service/.
