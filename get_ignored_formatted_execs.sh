get_bins(){
    cat .ignored_execs.txt | grep 'bin/[a-z].*'|cut -d'/' -f2|grep -v '^$'
}

get_bins | xargs -I % echo -e '"exec": "%"' \
    | tr '\n' '|'
