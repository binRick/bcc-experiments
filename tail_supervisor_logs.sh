source setup.sh
while :; do timeout 30 reap -x tail -q -n0 -F service/*/log/main/current || sleep 5; sleep .01; done
