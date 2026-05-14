################################################################################
#
# nvidia-580
#
################################################################################

NVIDIA_580_VERSION = 550.120
NVIDIA_580_SUFFIX = $(if $(BR2_x86_64),_64)
NVIDIA_580_SITE = http://download.nvidia.com/XFree86/Linux-x86$(NVIDIA_580_SUFFIX)/$(NVIDIA_580_VERSION)
NVIDIA_580_SOURCE = NVIDIA-Linux-x86$(NVIDIA_580_SUFFIX)-$(NVIDIA_580_VERSION)$(if $(BR2_x86_64),-no-compat32).run
NVIDIA_580_LICENSE = NVIDIA Software License
NVIDIA_580_LICENSE_FILES = LICENSE
NVIDIA_580_REDISTRIBUTE = NO
NVIDIA_580_INSTALL_STAGING = YES

ifeq ($(BR2_PACKAGE_NVIDIA_580_XORG),y)

NVIDIA_580_DEPENDENCIES += mesa3d libglvnd

# --- FIX: ADDED libOpenGL.so.0 FOR MODERN GLVND WAYLAND SUPPORT ---
NVIDIA_580_LIBS_GL = \
    libGLX.so.0 \
    libGL.so.1.7.0 \
    libOpenGL.so.0 \
    libGLX_nvidia.so.$(NVIDIA_580_VERSION)

NVIDIA_580_LIBS_EGL = \
    libEGL.so.1.1.0 \
    libGLdispatch.so.0 \
    libEGL_nvidia.so.$(NVIDIA_580_VERSION)

NVIDIA_580_LIBS_GLES = \
    libGLESv1_CM.so.1.2.0 \
    libGLESv2.so.2.1.0 \
    libGLESv1_CM_nvidia.so.$(NVIDIA_580_VERSION) \
    libGLESv2_nvidia.so.$(NVIDIA_580_VERSION)

NVIDIA_580_LIBS_MISC = \
    libnvidia-allocator.so.$(NVIDIA_580_VERSION) \
    libnvidia-cfg.so.$(NVIDIA_580_VERSION) \
    libnvidia-eglcore.so.$(NVIDIA_580_VERSION) \
    libnvidia-wayland-client.so.${NVIDIA_580_VERSION} \
    libnvidia-glcore.so.$(NVIDIA_580_VERSION) \
    libnvidia-glsi.so.$(NVIDIA_580_VERSION) \
    libnvidia-gpucomp.so.$(NVIDIA_580_VERSION) \
    libnvidia-tls.so.$(NVIDIA_580_VERSION) \
    libvdpau_nvidia.so.$(NVIDIA_580_VERSION):vdpau/ \
    libnvidia-ml.so.$(NVIDIA_580_VERSION)

NVIDIA_580_LIBS += \
    $(NVIDIA_580_LIBS_GL) \
    $(NVIDIA_580_LIBS_EGL) \
    $(NVIDIA_580_LIBS_GLES) \
    $(NVIDIA_580_LIBS_MISC)

NVIDIA_580_PROGS += \
    nvidia-smi \
    nvidia-xconfig \
    nvidia-settings \
    nvidia-bug-report.sh

ifeq ($(BR2_PACKAGE_NVIDIA_580_PRIVATE_LIBS),y)
NVIDIA_580_LIBS += \
    libnvidia-fbc.so.$(NVIDIA_580_VERSION)
endif

NVIDIA_580_LIBS += \
    nvidia_drv.so:xorg/modules/drivers/ \
    libglxserver_nvidia.so.$(NVIDIA_580_VERSION):xorg/modules/extensions/

define NVIDIA_580_SYMLINK_LIBGLX
    install -d -m 0755 $(TARGET_DIR)/opt/nvidia-580/xorg/modules/extensions
    ln -sf libglxserver_nvidia.so.$(NVIDIA_580_VERSION) \
        $(TARGET_DIR)/opt/nvidia-580/xorg/modules/extensions/libglx.so
endef

endif # X drivers

ifeq ($(BR2_PACKAGE_NVIDIA_580_CUDA),y)
NVIDIA_580_LIBS += \
    libcuda.so.$(NVIDIA_580_VERSION) \
    libnvidia-compiler.so.$(NVIDIA_580_VERSION) \
    libnvcuvid.so.$(NVIDIA_580_VERSION) \
    libnvidia-ptxjitcompiler.so.$(NVIDIA_580_VERSION) \
    libnvidia-encode.so.$(NVIDIA_580_VERSION)
ifeq ($(BR2_PACKAGE_NVIDIA_580_CUDA_PROGS),y)
NVIDIA_580_PROGS += nvidia-cuda-mps-control nvidia-cuda-mps-server
endif
endif

ifeq ($(BR2_PACKAGE_NVIDIA_580_OPENCL),y)
NVIDIA_580_LIBS += \
    libOpenCL.so.1.0.0 \
    libnvidia-opencl.so.$(NVIDIA_580_VERSION)
NVIDIA_580_DEPENDENCIES += xlib_libX11 xlib_libXext
# --- FIX: STRIPPED TRAPPED PROVIDERS FROM HERE ---
NVIDIA_580_PROVIDES += libopencl
endif

ifeq ($(BR2_PACKAGE_NVIDIA_580_MODULE),y)

NVIDIA_580_MODULES = nvidia nvidia-modeset nvidia-drm
ifeq ($(BR2_x86_64),y)
NVIDIA_580_MODULES += nvidia-uvm
endif

NVIDIA_580_MODULE_MAKE_OPTS = \
    IGNORE_CC_MISMATCH=1 \
    NV_KERNEL_SOURCES="$(LINUX_DIR)" \
    NV_KERNEL_OUTPUT="$(LINUX_DIR)" \
    NV_KERNEL_MODULES="$(NVIDIA_580_MODULES)"

NVIDIA_580_MODULE_SUBDIRS = kernel

$(eval $(kernel-module))

endif # BR2_PACKAGE_NVIDIA_580_MODULE == y

define NVIDIA_580_EXTRACT_CMDS
    $(SHELL) $(NVIDIA_580_DL_DIR)/$(NVIDIA_580_SOURCE) --extract-only --target \
        $(@D)/tmp-extract
    chmod u+w -R $(@D)
    mv $(@D)/tmp-extract/* $(@D)/tmp-extract/.manifest $(@D)
    rm -rf $(@D)/tmp-extract
endef

define NVIDIA_580_INSTALL_LIB
    $(INSTALL) -D -m 0644 $(@D)/$(1) $(2)$(notdir $(1))
    libsoname="$$( $(TARGET_READELF) -d "$(@D)/$(1)" \
        |sed -r -e '/.*\(SONAME\).*\[(.*)\]$$/!d; s//\1/;' )"; \
    if [ -n "$${libsoname}" -a "$${libsoname}" != "$(notdir $(1))" ]; then \
        ln -sf $(notdir $(1)) $(2)$${libsoname}; \
    fi
    baseso=$(firstword $(subst .,$(space),$(notdir $(1)))).so; \
    if [ -n "$${baseso}" -a "$${baseso}" != "$(notdir $(1))" ]; then \
        ln -sf $(notdir $(1)) $(2)$${baseso}; \
    fi
endef

define NVIDIA_580_INSTALL_LIBS
    $(foreach lib,$(NVIDIA_580_LIBS),
        $(call NVIDIA_580_INSTALL_LIB,$(word 1,$(subst :, ,$(lib))), \
            $(1)/opt/nvidia-580/$(word 2,$(subst :, ,$(lib))))
    )
endef

# For staging, install libraries and development files
define NVIDIA_580_INSTALL_STAGING_CMDS
    $(call NVIDIA_580_INSTALL_LIBS,$(STAGING_DIR))

    # Expose the core GL and EGL libraries to the C compiler in the standard path
    $(INSTALL) -D -m 0755 $(@D)/libGL.so.1.7.0 $(STAGING_DIR)/usr/lib/libGL.so.1.7.0
    ln -sf libGL.so.1.7.0 $(STAGING_DIR)/usr/lib/libGL.so.1
    ln -sf libGL.so.1 $(STAGING_DIR)/usr/lib/libGL.so

    # --- FIX: ADDED libOpenGL.so.0 ---
    $(INSTALL) -D -m 0755 $(@D)/libOpenGL.so.0 $(STAGING_DIR)/usr/lib/libOpenGL.so.0
    ln -sf libOpenGL.so.0 $(STAGING_DIR)/usr/lib/libOpenGL.so

    $(INSTALL) -D -m 0755 $(@D)/libEGL.so.1.1.0 $(STAGING_DIR)/usr/lib/libEGL.so.1.1.0
    ln -sf libEGL.so.1.1.0 $(STAGING_DIR)/usr/lib/libEGL.so.1
    ln -sf libEGL.so.1 $(STAGING_DIR)/usr/lib/libEGL.so

    $(INSTALL) -D -m 0755 $(@D)/libGLESv2.so.2.1.0 $(STAGING_DIR)/usr/lib/libGLESv2.so.2.1.0
    ln -sf libGLESv2.so.2.1.0 $(STAGING_DIR)/usr/lib/libGLESv2.so.2
    ln -sf libGLESv2.so.2 $(STAGING_DIR)/usr/lib/libGLESv2.so

    # Expose the GLVND dispatcher dependencies
    $(INSTALL) -D -m 0755 $(@D)/libGLX.so.0 $(STAGING_DIR)/usr/lib/libGLX.so.0
    ln -sf libGLX.so.0 $(STAGING_DIR)/usr/lib/libGLX.so

    $(INSTALL) -D -m 0755 $(@D)/libGLdispatch.so.0 $(STAGING_DIR)/usr/lib/libGLdispatch.so.0
    ln -sf libGLdispatch.so.0 $(STAGING_DIR)/usr/lib/libGLdispatch.so

    # Generate pkg-config files for Meson
    mkdir -p $(STAGING_DIR)/usr/lib/pkgconfig
    printf "Name: gl\nDescription: OpenGL library\nVersion: 1.2\nLibs: -L/usr/lib -lGL\nCflags: -I/usr/include\n" > $(STAGING_DIR)/usr/lib/pkgconfig/gl.pc
    printf "Name: egl\nDescription: EGL library\nVersion: 1.5\nLibs: -L/usr/lib -lEGL\nCflags: -I/usr/include\n" > $(STAGING_DIR)/usr/lib/pkgconfig/egl.pc
    printf "Name: glesv2\nDescription: GLESv2 library\nVersion: 2.0\nLibs: -L/usr/lib -lGLESv2\nCflags: -I/usr/include\n" > $(STAGING_DIR)/usr/lib/pkgconfig/glesv2.pc
    cp -a $(BUILD_DIR)/mesa3d-*/include/* $(STAGING_DIR)/usr/include/
endef


# For target, install libraries and X.org modules
define NVIDIA_580_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/libEGL_nvidia.so.$(NVIDIA_580_VERSION) $(TARGET_DIR)/usr/lib/libEGL_nvidia.so.0
    $(INSTALL) -D -m 0755 $(@D)/libGLESv2_nvidia.so.$(NVIDIA_580_VERSION) $(TARGET_DIR)/usr/lib/libGLESv2_nvidia.so.2
    $(INSTALL) -D -m 0755 $(@D)/libGLX_nvidia.so.$(NVIDIA_580_VERSION) $(TARGET_DIR)/usr/lib/libGLX_nvidia.so.0
    $(INSTALL) -D -m 0755 $(@D)/libnvidia-glcore.so.$(NVIDIA_580_VERSION) $(TARGET_DIR)/usr/lib/libnvidia-glcore.so.$(NVIDIA_580_VERSION)
    $(INSTALL) -D -m 0755 $(@D)/libnvidia-eglcore.so.$(NVIDIA_580_VERSION) $(TARGET_DIR)/usr/lib/libnvidia-eglcore.so.$(NVIDIA_580_VERSION)

    $(INSTALL) -D -m 0755 $(@D)/libnvidia-allocator.so.$(NVIDIA_580_VERSION) $(TARGET_DIR)/usr/lib/libnvidia-allocator.so.$(NVIDIA_580_VERSION)
    ln -sf libnvidia-allocator.so.$(NVIDIA_580_VERSION) $(TARGET_DIR)/usr/lib/libnvidia-allocator.so.1
    ln -sf libnvidia-allocator.so.1 $(TARGET_DIR)/usr/lib/libnvidia-allocator.so

    # EGL Wayland Bridge and Symlinks
    cp -dpf $(@D)/libnvidia-egl-wayland.so.1* $(TARGET_DIR)/usr/lib/
    ln -sf libnvidia-egl-wayland.so.1.1.13 $(TARGET_DIR)/usr/lib/libnvidia-egl-wayland.so.1
    ln -sf libnvidia-egl-wayland.so.1.1.13 $(TARGET_DIR)/usr/lib/libnvidia-egl-wayland.so

    # Vulkan & Wayland Internal Dependencies (SPIR-V, RT Core, PTX)
    $(INSTALL) -D -m 0755 $(@D)/libnvidia-glvkspirv.so.$(NVIDIA_580_VERSION) $(TARGET_DIR)/usr/lib/libnvidia-glvkspirv.so.$(NVIDIA_580_VERSION)
    $(INSTALL) -D -m 0755 $(@D)/libnvidia-rtcore.so.$(NVIDIA_580_VERSION) $(TARGET_DIR)/usr/lib/libnvidia-rtcore.so.$(NVIDIA_580_VERSION)
    $(INSTALL) -D -m 0755 $(@D)/libnvidia-ptxjitcompiler.so.$(NVIDIA_580_VERSION) $(TARGET_DIR)/usr/lib/libnvidia-ptxjitcompiler.so.$(NVIDIA_580_VERSION)

    # GBM Backend
    mkdir -p $(TARGET_DIR)/usr/lib/gbm
    find $(@D) -maxdepth 1 -name "libnvidia-egl-gbm.so.1.*" -exec $(INSTALL) -m 0755 {} $(TARGET_DIR)/usr/lib/gbm/nvidia-drm_gbm.so \;

    $(INSTALL) -D -m 0755 $(@D)/nvidia-smi $(TARGET_DIR)/usr/bin/nvidia-smi
    $(INSTALL) -D -m 4755 $(@D)/nvidia-modprobe $(TARGET_DIR)/usr/bin/nvidia-modprobe

    # For nvidia-smi
    $(INSTALL) -D -m 0755 $(@D)/libnvidia-ml.so.$(NVIDIA_580_VERSION) $(TARGET_DIR)/usr/lib/libnvidia-ml.so.$(NVIDIA_580_VERSION)
    ln -sf libnvidia-ml.so.$(NVIDIA_580_VERSION) $(TARGET_DIR)/usr/lib/libnvidia-ml.so.1
    ln -sf libnvidia-ml.so.1 $(TARGET_DIR)/usr/lib/libnvidia-ml.so

    $(INSTALL) -D -m 0755 $(@D)/libnvidia-glsi.so.$(NVIDIA_580_VERSION) $(TARGET_DIR)/usr/lib/libnvidia-glsi.so.$(NVIDIA_580_VERSION)
    $(INSTALL) -D -m 0755 $(@D)/libnvidia-tls.so.$(NVIDIA_580_VERSION) $(TARGET_DIR)/usr/lib/libnvidia-tls.so.$(NVIDIA_580_VERSION)

    $(INSTALL) -D -m 0755 $(@D)/libnvidia-gpucomp.so.$(NVIDIA_580_VERSION) $(TARGET_DIR)/usr/lib/libnvidia-gpucomp.so.$(NVIDIA_580_VERSION)

    $(INSTALL) -D -m 0755 $(@D)/libGL.so.1.7.0 $(TARGET_DIR)/usr/lib/libGL.so.1.7.0
    ln -sf libGL.so.1.7.0 $(TARGET_DIR)/usr/lib/libGL.so.1
    ln -sf libGL.so.1 $(TARGET_DIR)/usr/lib/libGL.so

    # --- FIX: ADDED libOpenGL.so.0 ---
    $(INSTALL) -D -m 0755 $(@D)/libOpenGL.so.0 $(TARGET_DIR)/usr/lib/libOpenGL.so.0
    ln -sf libOpenGL.so.0 $(TARGET_DIR)/usr/lib/libOpenGL.so

    $(INSTALL) -D -m 0755 $(@D)/libEGL.so.1.1.0 $(TARGET_DIR)/usr/lib/libEGL.so.1.1.0
    ln -sf libEGL.so.1.1.0 $(TARGET_DIR)/usr/lib/libEGL.so.1
    ln -sf libEGL.so.1 $(TARGET_DIR)/usr/lib/libEGL.so

    $(INSTALL) -D -m 0755 $(@D)/libGLESv2.so.2.1.0 $(TARGET_DIR)/usr/lib/libGLESv2.so.2.1.0
    ln -sf libGLESv2.so.2.1.0 $(TARGET_DIR)/usr/lib/libGLESv2.so.2
    ln -sf libGLESv2.so.2 $(TARGET_DIR)/usr/lib/libGLESv2.so

    $(INSTALL) -D -m 0755 $(@D)/libGLX.so.0 $(TARGET_DIR)/usr/lib/libGLX.so.0
    ln -sf libGLX.so.0 $(TARGET_DIR)/usr/lib/libGLX.so

    $(INSTALL) -D -m 0755 $(@D)/libGLdispatch.so.0 $(TARGET_DIR)/usr/lib/libGLdispatch.so.0
    ln -sf libGLdispatch.so.0 $(TARGET_DIR)/usr/lib/libGLdispatch.so

    # Generate JSON configurations for EGL, Vulkan, and GLVND
    mkdir -p $(TARGET_DIR)/usr/share/egl/egl_external_platform.d
    echo '{ "file_format_version" : "1.0.0", "ICD" : { "library_path" : "libnvidia-egl-wayland.so.1" } }' \
        > $(TARGET_DIR)/usr/share/egl/egl_external_platform.d/10_nvidia_wayland.json

    mkdir -p $(TARGET_DIR)/usr/share/vulkan/icd.d
    echo '{ "file_format_version" : "1.0.0", "ICD": { "library_path": "libGLX_nvidia.so.0", "api_version" : "1.3.277" } }' \
        > $(TARGET_DIR)/usr/share/vulkan/icd.d/nvidia_icd.json

    mkdir -p $(TARGET_DIR)/usr/share/glvnd/egl_vendor.d
    echo '{ "file_format_version" : "1.0.0", "ICD" : { "library_path" : "libEGL_nvidia.so.0" } }' \
        > $(TARGET_DIR)/usr/share/glvnd/egl_vendor.d/10_nvidia.json

endef

# Due to a conflict with xserver_xorg-server, this needs to be performed when
# finalizing the target filesystem to make sure this version is used.
NVIDIA_580_TARGET_FINALIZE_HOOKS += NVIDIA_580_SYMLINK_LIBGLX

$(eval $(generic-package))
