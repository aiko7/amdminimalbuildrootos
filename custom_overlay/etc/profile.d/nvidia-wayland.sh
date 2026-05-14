#export GBM_BACKEND=nvidia-drm
#export __GLX_VENDOR_LIBRARY_NAME=nvidia
#export WLR_NO_HARDWARE_CURSORS=1
#export WLR_DRM_NO_MODIFIERS=1
#export WLR_RENDERER=gles2
#export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json
#export WAYLAND_DEBUG=1
#export EGL_LOG_LEVEL=debug
#export GDK_BACKEND=wayland
#export WLR_DRM_DEVICES=/dev/dri/card1

export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=sway

export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export WLR_NO_HARDWARE_CURSORS=1

export WLR_EGL_NO_MODIFIERS=1
export WLR_DRM_NO_MODIFIERS=1
export WLR_RENDERER=pixman


export XDG_RUNTIME_DIR=/tmp/xdg
mkdir -p /tmp/xdg
chmod 0700 /tmp/xdg

ln -sf /usr/lib/libnvidia-egl-wayland.so.1.1.13 /usr/lib/libnvidia-egl-wayland.so.1
ln -sf /usr/lib/libnvidia-egl-wayland.so.1.1.13 /usr/lib/libnvidia-egl-wayland.so

