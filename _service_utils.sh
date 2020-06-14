SERVICES_PATH=~/bcc-experiments/service
LOG_USER=root
DEFAULT_LOG_MODE=json
MULTILOG_PROCESSOR_SCRIPT=~root/bcc-experiments/bin/MULTILOG_PROCESSOR.sh
LOG_FILTER_LOG_MAX_SIZE_KB=100
RECORD_RATE_FILES_ENABLED=1

record_rate(){
        if [[ "$RECORD_RATE_FILES_ENABLED" == "1" ]];then
		command pv --force 2> "$my_rate_path"
	else
		cat 
	fi
}

CREATE_LOG_PATH(){
        P="$SERVICES_PATH/exec_logger/.sublog_${1}"
        [[ ! -d "$P" ]] && mkdir -p "$P"
        echo -e "$P"
}

CREATE_EXEC_FILTER(){
        #echo -e "$1"
        echo -e "\"exec\": \"${1}\""
}
_RAW_LOG_FILTER(){
        setuidgid $LOG_USER multilog \
            s$((${LOG_FILTER_LOG_MAX_SIZE_KB}*1024)) n2 \
            ${1}/main

}
RAW_LOG_FILTER(){
        tee >( _RAW_LOG_FILTER "$1" )
}

MULTILOG_PROCESSOR="!${MULTILOG_PROCESSOR_SCRIPT}"

LOG_FILTER(){
        my_rate_path=${1}/rate
	my_log_cmd=record_rate
	#my_log_cmd="pv --force 2> $my_rate_path"
        tee >( \
                   reap -x grep "${2}" \
                    | eval $my_log_cmd \
                    | setuidgid $LOG_USER multilog \
                      s$((${LOG_FILTER_LOG_MAX_SIZE_KB}*1024)) n2 \
                      ${1}/main ${MULTILOG_PROCESSOR}
                )
}


CREATE_LOG_FILTER(){
        MY_LOG_PATH="$(CREATE_LOG_PATH "$1" "${2:-$DEFAULT_LOG_MODE}")"
        if [[ "$recording_rate" == "1" ]]; then
                RAW_LOG_FILTER "$MY_LOG_PATH" "$MY_LOG_FILTER"
        else
                MY_LOG_FILTER="$(CREATE_EXEC_FILTER "$1")"
                LOG_FILTER "$MY_LOG_PATH" "$MY_LOG_FILTER"
        fi
}
