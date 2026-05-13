#!/bin/sh

export DISPLAY=:0
mkdir -p /tmp/xdg
chmod 0700 /tmp/xdg
export XDG_RUNTIME_DIR=/tmp/xdg

eval $(dbus-launch --sh-syntax)
cd /opt/zoolander
cage -- sh -c "sleep 1 && wlr-randr --output DP-2 --above DP-4 && exec ./zoolander"
#openbox &

#xcompmgr -c &


#export vblank_mode=0
#export CLUTTER_VBLANK=none

