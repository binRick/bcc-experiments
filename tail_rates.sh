tail_cmds="$(command find service -type f -name rate|xargs -I % echo -ne '"tail -F -n0 -q % 2>/dev/null" ')"
export TMUX_XPANES_PANE_BORDER_STATUS="top"
export TMUX_XPANES_PANE_BORDER_FORMAT="#[bg=green,fg=black] #T#{?pane_pipe,[Log],} #[default]"
TIMEOUT="3600"
XPANES_TIMEOUT="timeout $TIMEOUT"
XPANES_EXEC="$XPANES_TIMEOUT xpanes"
XPANES_ARGS="-s -t -l ev"
DSTAT="command dstat -alp --top-cpu --top-cputime-avg 5 1500"
cmd="$XPANES_EXEC $XPANES_ARGS -e \
$tail_cmds \
\"echo OK\""


#>&2 echo -e $cmd
eval $cmd

