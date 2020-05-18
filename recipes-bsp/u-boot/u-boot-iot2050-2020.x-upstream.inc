#
# Copyright (c) Siemens AG, 2020
#
# Authors:
#  Jan Kiszka <jan.kiszka@siemens.com>
#
# This file is subject to the terms and conditions of the MIT License.  See
# COPYING.MIT file in the top-level directory.
#

require u-boot-iot2050.inc

SRC_URI += " \
    git://github.com/siemens/u-boot.git;branch=${U_BOOT_BRANCH};rev=${U_BOOT_BRANCH} \
    file://atf/0001-feat-add-atf-support-to-iot2050-platform.patch;patchdir=${WORKDIR}/atf \
    file://optee/0001-feat-add-optee-support-to-iot2050-platform.patch;patchdir=${WORKDIR}/optee \
    "

U_BOOT_BRANCH = "jan/iot2050"
U_BOOT_BIN = "u-boot.itb"
U_BOOT_RULES = "iot2050-uboot-build-rules"
ATF_REV   = "996d37930996c2fa39eb091508b5ad4e0d69ad35"
OPTEE_REV = "e260ea8dde9669308336d194abec8dcc18784216"
