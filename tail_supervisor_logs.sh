while :; do timeout 30 reap -vx tail -q -n0 -F service/*/log/main/current || sleep 5; sleep .01; done
