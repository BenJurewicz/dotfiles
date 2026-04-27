#!/bin/bash

# Get the number of workspaces on the currently focused monitor
count=$(aerospace list-workspaces --monitor focused --count)

if [ "$count" -gt 1 ]; then
    # If there is more than one workspace, it's safe to move it
    aerospace move-workspace-to-monitor --wrap-around next
else
    # If it's the last workspace, do not move it and send a notification
    workspace=$(aerospace list-workspaces --focused --format "%{workspace}")
    monitor=$(aerospace list-monitors --focused --format "%{monitor-name}")
    osascript -e "display notification \"Cannot move workspace '$workspace' from monitor '$monitor' (it is the last one)\" with title \"Aerospace\""
fi

