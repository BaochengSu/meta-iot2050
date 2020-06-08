#
# Copyright (c) Siemens AG, 2020
#
# Authors:
#  Su Baocheng <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT

# Cross-compilation is not supported for the default Debian kernels.
# For example, package with kernel headers for ARM:
#   linux-headers-armmp
# has hard dependencies from linux-compiler-gcc-4.8-arm, what
# conflicts with the host binaries.
python() {
    if d.getVar('KERNEL_NAME') in [
        'armmp',
        'arm64',
        'rpi-rpfv',
        'amd64',
        '686-pae',
        '4kc-malta',
    ]:
        d.setVar('ISAR_CROSS_COMPILE', '0')
}

require recipes-kernel/linux-module/module.inc

SRC_URI += "git://git.ti.com/graphics/omap5-sgx-ddk-linux.git;branch=${PVRSRVKM_BRANCH};rev=${PVRSRVKM_REV}"

SRC_URI += "file://rules"

PVRSRVKM_BRANCH = "ti-img-sgx/1.17.4948957/k4.19"
PVRSRVKM_REV = "2a777b8fb72a89d299b82845d42b63b2a2618daa"

S = "${WORKDIR}/git"

AUTOLOAD = "pvrsrvkm"

DESCRIPTION = "Kernel drivers for the PowerVR SGX chipset found in the TI SoCs"

do_prepare_build_append() {
    cp -f ${WORKDIR}/rules ${S}/debian/rules
}


#######################################################################


#EXTRA_OEMAKE += 'KERNELDIR="${STAGING_KERNEL_DIR}" TARGET_PRODUCT=${TARGET_PRODUCT} WINDOW_SYSTEM=nulldrmws'

