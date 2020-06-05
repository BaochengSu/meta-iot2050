#
# Copyright (c) Siemens AG, 2020
#
# Authors:
#  Su Baocheng <baocheng.su@siemens.com>
#
# SPDX-License-Identifier: MIT

inherit dpkg

SRC_URI += "git://git.ti.com/graphics/omap5-sgx-ddk-um-linux.git;branch=${SRC_BRANCH};rev=${SRC_REV} \
    file://0001-refact-change-the-libdir-for-debian-buster-distro.patch \
    file://0002-refact-add-header-to-rc.pvr-for-new-update.rc-comman.patch \
    file://debian \
    "

SRC_BRANCH = "ti-img-sgx/thud/${PV}"
SRC_REV = "2a2e5bb090ced870d73ed4edbc54793e952cc6d8"

S = "${WORKDIR}/git"
TARGET_PRODUCT = "ti654x"
DESTDIR = "/"

do_prepare_build[cleandirs] += "${S}/debian"
do_prepare_build() {
    cp -r ${WORKDIR}/debian ${S}/
    deb_add_changelog
}


#######

# TODO: "update-rc.d -f rc.pvr defaults"

# This is the rc.pvr update-rc.d command copied from arago project, just for reference.
#INITSCRIPT_NAME = "rc.pvr"
#INITSCRIPT_PARAMS = "defaults 8"

#inherit update-rc.d
