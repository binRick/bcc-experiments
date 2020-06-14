SERVICES_PATH=~/bcc-experiments/service
LOG_USER=root
DEFAULT_LOG_MODE=json
LOG_FILTER_LOG_MAX_SIZE_KB=32
record_rate(){

        pv --force 2> "$my_rate_path" | recording_rate=1 CREATE_LOG_FILTER "$subfilter_name" "rate"
}

CREATE_LOG_PATH(){
        P=$SERVICES_PATH/exec_logger/.sublog_${1}.${2:-$DEFAULT_LOG_MODE}
        [[ ! -d "$P" ]] && mkdir -p "$P"
        echo -e "$P"
}

CREATE_EXEC_FILTER(){
        #echo -e "$1"
        echo -e "\"exec\": \"${1}\""
}
_RAW_LOG_FILTER(){
        setuidgid $LOG_USER multilog \
            s$((${$LOG_FILTER_LOG_MAX_SIZE_KB}*1024)) n1 \
            ${1}/main

}
RAW_LOG_FILTER(){
        tee >( _RAW_LOG_FILTER "$1" )
}

LOG_FILTER(){
        my_rate_path=${1}/rate
        tee >( \
                   reap -x grep "${2}" \
                    | pv --force 2> $my_rate_path \
                    | setuidgid $LOG_USER multilog \
                      s$((${LOG_FILTER_LOG_MAX_SIZE_KB}*1024)) n1 \
                      ${1}/main
                )
}


CREATE_LOG_FILTER(){
        MY_LOG_PATH="$(CREATE_LOG_PATH "$1" "$2")"
        if [[ "$recording_rate" == "1" ]]; then
                RAW_LOG_FILTER "$MY_LOG_PATH" "$MY_LOG_FILTER"
        else
                MY_LOG_FILTER="$(CREATE_EXEC_FILTER "$1")"
                LOG_FILTER "$MY_LOG_PATH" "$MY_LOG_FILTER"
        fi
}
