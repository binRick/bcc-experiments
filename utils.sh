create_service_log_filter_cmd(){
	eval $(yaml2bash /root/bcc-experiments/etc/service_config.yaml)
	echo -e "load_service_config_yaml_config && y2b_traverse Y2B[services][exec_logger][subloggers] |cut -d'=' -f2|xargs -I {} echo -ne '| CREATE_LOG_FILTER {}'"
}
get_service_config_yaml_config(){
	echo -e "$INIT_DIR/etc/service_config.yaml"
}
load_service_config_yaml_config(){
	#INIT_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	#eval $(yaml2bash $(get_service_config_yaml_config))
	eval $(yaml2bash /root/bcc-experiments/etc/service_config.yaml) 
#&& \
		#>&2 y2b_traverse Y2B

}
get_my_pids(){
	(for pid in $(ps -ao pid=); do cat /proc/$pid/environ 2>/dev/null  |tr '\0' '\n' |grep -q ^BCC_EXPERIMENTS_PROCESS=1$ && echo $pid; done)|sort -u|grep '^[0-9]'
}
kill_my_pids(){
  (
	while get_my_pids; do 
		kill $(get_my_pids) && sleep 5 && kill -9 $(get_my_pids); sleep 1; 
	done
  ) >/dev/null 2>&1
}
function no_ctrlc(){
    let ctrlc_count++
    echo
    if [[ $ctrlc_count == 1 ]]; then
        echo "Stop that."
    elif [[ $ctrlc_count == 2 ]]; then
        echo "Once more and I quit."
    else
        echo "That's it.  I quit."
        exit
    fi
}
uuid(){
    local N B T

    for (( N=0; N < 16; ++N ))
    do
        B=$(( $RANDOM%255 ))

        if (( N == 6 ))
        then
            printf '4%x' $(( B%15 ))
        elif (( N == 8 ))
        then
            local C='89ab'
            printf '%c%x' ${C:$(( $RANDOM%${#C} )):1} $(( B%15 ))
        else
            printf '%02x' $B
        fi

        for T in 3 5 7 9
        do
            if (( T == N ))
            then
                printf '-'
                break
            fi
        done
    done

    echo
}
rand_str(){
    LEN=${1:-8}
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-$LEN} | egrep '^[a-z]|^[A-Z]' | head -n 1
}
