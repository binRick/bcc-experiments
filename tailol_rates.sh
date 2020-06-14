

tail_files="$(command find service -name rate|xargs -I % echo -ne '% ')"
cmd="tailol $tail_files"

echo -e $cmd
