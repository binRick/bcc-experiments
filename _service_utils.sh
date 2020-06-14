SERVICES_PATH=~/bcc-experiments/service
LOG_USER=root
DEFAULT_LOG_MODE=json
MULTILOG_PROCESSOR_SCRIPT=~root/bcc-experiments/bin/MULTILOG_PROCESSOR.sh
LOG_FILTER_LOG_MAX_SIZE_KB=100
#eval $(yaml2bash /root/bcc-experiments/etc/service_config.yaml)

CREATE_LOG_PATH(){
        P="$SERVICES_PATH/exec_logger/.sublog_${1}"
        [[ ! -d "$P" ]] && mkdir -p "$P"
        echo -e "$P"
}

CREATE_EXEC_FILTER(){
        echo -e "\"exec\": \"${1}\""
}
MULTILOG_PROCESSOR="!${MULTILOG_PROCESSOR_SCRIPT}"

LOG_FILTER(){
        my_rate_path=${1}/rate
        command grep "${2}" | command pv --force 2> "$my_rate_path" | command reap -x \
		command tee >( \
		                   command setuidgid $LOG_USER \
				     command multilog \
				       s$((${LOG_FILTER_LOG_MAX_SIZE_KB}*1024)) n2 \
				       ${MULTILOG_PROCESSOR} \
			  	       ${1}/main
                              )
}

CREATE_LOG_FILTER(){
        MY_LOG_PATH="$(CREATE_LOG_PATH "$1" "${2:-$DEFAULT_LOG_MODE}")"
	MY_LOG_FILTER="$(CREATE_EXEC_FILTER "$1")"
        LOG_FILTER "$MY_LOG_PATH" "$MY_LOG_FILTER"
}
