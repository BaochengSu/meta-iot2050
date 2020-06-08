#
# Copyright (c) Siemens AG, 2018
#
# This file is subject to the terms and conditions of the MIT License.  See
# COPYING.MIT file in the top-level directory.
#

require recipes-kernel/linux/linux-custom.inc

SRC_URI += "git://git.ti.com/processor-sdk/processor-sdk-linux.git;branch=${KERNEL_BRANCH};rev=${KERNEL_REV}"

SRC_URI += "file://${KERNEL_DEFCONFIG}"
SRC_URI += "file://${KERNEL_DEFCONFIG_EXTRA}"

SRC_URI += " \
    file://0001-iot2050-add-iot2050-platform-support.patch \
    file://0002-Add-support-for-U9300C-TD-LTE-module.patch \
    file://0003-feat-Add-CP210x-driver-support-to-software-flow-cont.patch \
    file://0004-fix-disable-usb-lpm-to-fix-usb-device-reset.patch \
    file://0005-Fix-DP-maybe-not-display-problem.patch \
    file://0006-fix-fix-the-hardware-flow-function-of-cp2102n24.patch \
    file://0007-feat-add-io-expander-pcal9535-support.patch \
    file://0008-feat-modify-kernel-to-load-fw-from-MTD-for-pru-rtu.patch \
    file://0009-setting-the-RJ45-port-led-behavior.patch \
    file://0010-fix-clear-the-cycle-buffer-of-serial.patch \
    file://0011-refactor-move-ioexpander-node-to-mcu-i2c0-for-LM5.patch \
    file://0012-feat-extend-led-panic-indicator-on-and-off.patch \
    file://0013-feat-change-mmc-order-using-alias-in-dts.patch \
    file://0014-iot2050-Roll-back-basic-dtb-to-V01.00.00.1-release.patch \
    file://0001-feat-enable-gpu-for-iot2050.patch"

KERNEL_BRANCH = "processor-sdk-linux-4.19.y"
KERNEL_REV = "be5389fd85b69250aeb1ba477447879fb392152f"

KERNEL_DEFCONFIG = "iot2050_defconfig_base"
KERNEL_DEFCONFIG_EXTRA = "iot2050_defconfig_extra.cfg"

S = "${WORKDIR}/git"
