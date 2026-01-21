#!/bin/bash

# TODO: Make this work with any number of monitor by swapping workspaces
# between the current one and the last focused one.
#
# Aerospace does not keep info about the last focused monitor, but we can
# get it ourselves, by using exec-on-workspace-change.
# Link: https://nikitabobko.github.io/AeroSpace/guide#exec-on-workspace-change-callback
# And by using the exec env vars.
# Link: https://nikitabobko.github.io/AeroSpace/guide#exec-env-vars
#
# The plan:
# Two env vars: current_monitor and last_monitor
# exec-on-workspace-change:
# new_monitor = aerospace list-monitors --focused --format '%{monitor-id}'
# if (new_monitor != current_monitor){
#       last_monitor = current_monitor;
#       current_monitor = new_monitor
# }
#
# Then in the script simply read these env values as m1 and m2.

# Get all montior IDs
monitors=($(aerospace list-monitors --format '%{monitor-id}' | xargs))
focused_monitor=$(aerospace list-monitors --focused --format '%{monitor-id}')

# Ensure there are exactly two monitors for a clean swap
if [ ${#monitors[@]} -ne 2 ]; then
    # echo "Error: This script requires exactly 2 monitors to swap workspaces."
    osascript -e "display notification \"This script currently requires two monitors to work\" with title \"Aerospace: swap-monitors.sh\""
    exit 1
fi

m1=${monitors[0]}
m2=${monitors[1]}

# Identify the workspace currently visible on each monitor
w1=$(aerospace list-workspaces --monitor "$m1" --visible)
w2=$(aerospace list-workspaces --monitor "$m2" --visible)

# NOTE: If things break or become unstable
# add more sleeps or increase the duration :)

# Swap
aerospace focus-monitor "$m1"
aerospace summon-workspace "$w2"
sleep 0.1

aerospace focus-monitor "$m2"
aerospace summon-workspace "$w1"
sleep 0.1

# Restore focus
aerospace focus-monitor "$focused_monitor"
