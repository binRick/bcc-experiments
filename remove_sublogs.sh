find service -type d -name ".sublog*" | xargs -I % echo -e "rm -rf %"
