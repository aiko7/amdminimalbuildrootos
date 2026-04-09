Minimal buildroot os for testing flutter application\
Built for AMD Ryzen Embedded V1807B. (x86_64 architecture)\
Using kernel 6.12.47\
System initilization is provided by BusyBox\
Using xorg display server with mesa3d enabled, using radeonsi gallium drivers, also provided is GBM, EGL and OpenGL ES libraries\
Kernal driver is amdgpu compiled as a loadable module (M)\
For window manager we use openbox and for compositing we use compmgr\
RELRO is set to partial as there were issues in starting our app with it set to full\
There are also a few basic linux utilities added that aren't strictly necessary but were useful such as parted, lsblk, resize2fs\

To launch our app i was doing\
export DISPLAY=:0 \
openbox & \
xcompmgr -c & \
eval $(dbus-launch --sh-syntax)\
export vblank_mode=0\
export CLUTTER_VBLANK=none\

and then finally running\
./app \
